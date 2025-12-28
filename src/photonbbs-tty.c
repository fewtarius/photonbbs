/*
 * PhotonBBS TTY Replacement for telnetd
 * 
 * This program replaces various telnetd implementations with a single, secure
 * TTY handler that creates a PTY and executes the PhotonBBS client.
 * 
 * Compatible with PhotonBBS daemon's telnetd calling patterns:
 * - Rocky/RHEL: -N -h -n -L client_path protocol ip nodeid
 * - BusyBox: -l "client_path protocol ip nodeid"  
 * - BSD: -E "client_path protocol ip nodeid" -h
 *
 * Copyright (C) 2025 Fewtarius
 * License: GPL v2
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#ifdef __APPLE__
#include <util.h>
#else
#include <pty.h>
#endif
#include <termios.h>
#include <signal.h>
#include <sys/wait.h>
#include <errno.h>
#include <fcntl.h>
#include <syslog.h>
#include <limits.h>
#include <sys/ioctl.h>
#include <ctype.h>
#include <pwd.h>

#define MAX_ARG_LEN 512
#define BUFFER_SIZE 4096

/* Telnet Protocol Constants */
#define IAC  255    /* Interpret As Command */
#define DONT 254    /* Request not to do option */
#define DO   253    /* Request to do option */
#define WONT 252    /* Refuse to do option */
#define WILL 251    /* Will do option */
#define SB   250    /* Sub-negotiation Begin */
#define GA   249    /* Go Ahead */
#define EL   248    /* Erase Line */
#define EC   247    /* Erase Character */
#define AYT  246    /* Are You There */
#define AO   245    /* Abort Output */
#define IP   244    /* Interrupt Process */
#define BREAK 243   /* Break */
#define DM   242    /* Data Mark */
#define NOP  241    /* No Operation */
#define SE   240    /* Sub-negotiation End */
#define EOR  239    /* End of Record */
#define ABORT 238   /* Abort */
#define SUSP 237    /* Suspend */
#define xEOF 236    /* End of File */

/* Telnet Options */
#define TELOPT_BINARY         0  /* Binary Transmission */
#define TELOPT_ECHO           1  /* Echo */
#define TELOPT_RCP            2  /* Reconnection */
#define TELOPT_SGA            3  /* Suppress Go Ahead */
#define TELOPT_NAMS           4  /* Approx Message Size Negotiation */
#define TELOPT_STATUS         5  /* Status */
#define TELOPT_TM             6  /* Timing Mark */
#define TELOPT_RCTE           7  /* Remote Controlled Trans and Echo */
#define TELOPT_NAOL           8  /* Output Line Width */
#define TELOPT_NAOP           9  /* Output Page Size */
#define TELOPT_NAOCRD        10  /* Output Carriage-Return Disposition */
#define TELOPT_NAOHTS        11  /* Output Horizontal Tab Stops */
#define TELOPT_NAOHTD        12  /* Output Horizontal Tab Disposition */
#define TELOPT_NAOFFD        13  /* Output Formfeed Disposition */
#define TELOPT_NAOVTS        14  /* Output Vertical Tabstops */
#define TELOPT_NAOVTD        15  /* Output Vertical Tab Disposition */
#define TELOPT_NAOLFD        16  /* Output Linefeed Disposition */
#define TELOPT_XASCII        17  /* Extended ASCII */
#define TELOPT_LOGOUT        18  /* Logout */
#define TELOPT_BM            19  /* Byte Macro */
#define TELOPT_DET           20  /* Data Entry Terminal */
#define TELOPT_SUPDUP        21  /* SUPDUP */
#define TELOPT_SUPDUPOUTPUT  22  /* SUPDUP Output */
#define TELOPT_SNDLOC        23  /* Send Location */
#define TELOPT_TTYPE         24  /* Terminal Type */
#define TELOPT_EOR           25  /* End of Record */
#define TELOPT_TUID          26  /* TACACS User Identification */
#define TELOPT_OUTMRK        27  /* Output Marking */
#define TELOPT_TTYLOC        28  /* Terminal Location Number */
#define TELOPT_3270REGIME    29  /* Telnet 3270 Regime */
#define TELOPT_X3PAD         30  /* X.3 PAD */
#define TELOPT_NAWS          31  /* Negotiate About Window Size */
#define TELOPT_TSPEED        32  /* Terminal Speed */
#define TELOPT_LFLOW         33  /* Remote Flow Control */
#define TELOPT_LINEMODE      34  /* Linemode */
#define TELOPT_XDISPLOC      35  /* X Display Location */
#define TELOPT_OLD_ENVIRON   36  /* Old Environment */
#define TELOPT_AUTHENTICATION 37 /* Authentication */
#define TELOPT_ENCRYPT       38  /* Encryption */
#define TELOPT_NEW_ENVIRON   39  /* New Environment */

/* Telnet State Machine */
enum telnet_state {
    TS_DATA = 0,    /* Normal data */
    TS_IAC,         /* IAC received */
    TS_WILL,        /* WILL received */
    TS_WONT,        /* WONT received */
    TS_DO,          /* DO received */
    TS_DONT,        /* DONT received */
    TS_SB,          /* Sub-negotiation */
    TS_SE           /* Sub-negotiation end */
};

/* Telnet negotiation state */
struct telnet_state_machine {
    enum telnet_state state;
    unsigned char sb_buf[256];  /* Sub-negotiation buffer */
    int sb_len;                 /* Sub-negotiation length */
    int binary_mode;            /* Binary transmission mode */
    int echo_mode;              /* Echo mode */
    int sga_mode;               /* Suppress Go Ahead */
};

/* Global flag for child process status */
static volatile sig_atomic_t child_exited = 0;
static volatile pid_t child_exit_pid = 0;

/* Hex logging for debugging */
#define ENABLE_HEX_LOG 1
static FILE *hex_log = NULL;

/* Initialize telnet state machine */
static void init_telnet_state(struct telnet_state_machine *ts) {
    ts->state = TS_DATA;
    ts->sb_len = 0;
    ts->binary_mode = 0;
    ts->echo_mode = 0;
    ts->sga_mode = 0;
}

/* SIGCHLD handler for child process reaping */
static void sigchld_handler(int sig) {
    int status;
    pid_t pid;
    
    (void)sig; /* Suppress unused parameter warning */
    
    /* Reap all available children */
    while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
        child_exited = 1;
        child_exit_pid = pid;
        syslog(LOG_INFO, "Child process %d exited with status %d", pid, WEXITSTATUS(status));
    }
}

/* Initialize hex logging */
static void init_hex_log() {
#if ENABLE_HEX_LOG
    hex_log = fopen("/dev/shm/telnet-hex.log", "a");
    if (hex_log) {
        setbuf(hex_log, NULL); /* Unbuffered for real-time logging */
        fprintf(hex_log, "\n=== NEW SESSION %ld ===\n", time(NULL));
    }
#endif
}

/* Log hex data */
static void hex_log_data(const char *label, const unsigned char *data, int len) {
#if ENABLE_HEX_LOG
    if (!hex_log) return;
    
    fprintf(hex_log, "[%ld] %s (%d bytes): ", time(NULL), label, len);
    for (int i = 0; i < len; i++) {
        fprintf(hex_log, "%02X ", data[i]);
    }
    fprintf(hex_log, "\n");
    fflush(hex_log);
#else
    (void)label;
    (void)data;
    (void)len;
#endif
}

/* Send telnet command */
static void send_telnet_cmd(int fd, unsigned char cmd, unsigned char option) {
    unsigned char buf[3] = {IAC, cmd, option};
    write(fd, buf, 3);
}

/* Send telnet sub-negotiation */
static void send_telnet_subneg(int fd, unsigned char option, 
                              const unsigned char *data, int len) {
    unsigned char buf[256];
    int pos = 0;
    
    buf[pos++] = IAC;
    buf[pos++] = SB;
    buf[pos++] = option;
    
    for (int i = 0; i < len && pos < 250; i++) {
        if (data[i] == IAC) {
            buf[pos++] = IAC;  /* Double IAC in subnegotiation */
        }
        buf[pos++] = data[i];
    }
    
    buf[pos++] = IAC;
    buf[pos++] = SE;
    
    write(fd, buf, pos);
}

/* Handle telnet option negotiations */
static void handle_telnet_option(struct telnet_state_machine *ts, int fd,
                                unsigned char cmd, unsigned char option) {
    switch (cmd) {
        case WILL:
            switch (option) {
                case TELOPT_ECHO:
                    /* Client will echo - we don't want that */
                    send_telnet_cmd(fd, DONT, TELOPT_ECHO);
                    break;
                case TELOPT_SGA:
                    /* Client will suppress go-ahead - accept */
                    send_telnet_cmd(fd, DO, TELOPT_SGA);
                    ts->sga_mode = 1;
                    break;
                case TELOPT_BINARY:
                    /* Client will use binary mode - accept */
                    send_telnet_cmd(fd, DO, TELOPT_BINARY);
                    ts->binary_mode = 1;
                    break;
                case TELOPT_TTYPE:
                    /* Client will send terminal type - accept */
                    send_telnet_cmd(fd, DO, TELOPT_TTYPE);
                    break;
                case TELOPT_NAWS:
                    /* Client will send window size - accept */
                    send_telnet_cmd(fd, DO, TELOPT_NAWS);
                    break;
                default:
                    /* Reject unknown options */
                    send_telnet_cmd(fd, DONT, option);
                    break;
            }
            break;
            
        case WONT:
            /* Client won't do something - acknowledge */
            send_telnet_cmd(fd, DONT, option);
            if (option == TELOPT_ECHO) ts->echo_mode = 0;
            if (option == TELOPT_SGA) ts->sga_mode = 0;
            if (option == TELOPT_BINARY) ts->binary_mode = 0;
            break;
            
        case DO:
            switch (option) {
                case TELOPT_ECHO:
                    /* Server should echo - accept */
                    send_telnet_cmd(fd, WILL, TELOPT_ECHO);
                    ts->echo_mode = 1;
                    break;
                case TELOPT_SGA:
                    /* Server should suppress go-ahead - accept */
                    send_telnet_cmd(fd, WILL, TELOPT_SGA);
                    ts->sga_mode = 1;
                    break;
                case TELOPT_BINARY:
                    /* Server should use binary mode - accept */
                    send_telnet_cmd(fd, WILL, TELOPT_BINARY);
                    ts->binary_mode = 1;
                    break;
                default:
                    /* Reject unknown options */
                    send_telnet_cmd(fd, WONT, option);
                    break;
            }
            break;
            
        case DONT:
            /* Client doesn't want us to do something - acknowledge */
            send_telnet_cmd(fd, WONT, option);
            if (option == TELOPT_ECHO) ts->echo_mode = 0;
            if (option == TELOPT_SGA) ts->sga_mode = 0;
            if (option == TELOPT_BINARY) ts->binary_mode = 0;
            break;
    }
}

/* Process telnet input and filter out protocol commands */
static int process_telnet_input(struct telnet_state_machine *ts, int fd,
                               const unsigned char *input, int len,
                               unsigned char *output, int max_output) {
    int output_len = 0;
    
    for (int i = 0; i < len; i++) {
        unsigned char c = input[i];
        
        switch (ts->state) {
            case TS_DATA:
                if (c == IAC) {
                    ts->state = TS_IAC;
                } else {
                    /* Regular data - pass through */
                    if (output_len < max_output) {
                        output[output_len++] = c;
                    }
                }
                break;
                
            case TS_IAC:
                switch (c) {
                    case IAC:
                        /* Escaped IAC - pass through as data */
                        if (output_len < max_output) {
                            output[output_len++] = IAC;
                        }
                        ts->state = TS_DATA;
                        break;
                    case WILL:
                        ts->state = TS_WILL;
                        break;
                    case WONT:
                        ts->state = TS_WONT;
                        break;
                    case DO:
                        ts->state = TS_DO;
                        break;
                    case DONT:
                        ts->state = TS_DONT;
                        break;
                    case SB:
                        ts->state = TS_SB;
                        ts->sb_len = 0;
                        break;
                    case GA:
                    case EL:
                    case EC:
                    case AYT:
                    case AO:
                    case IP:
                    case BREAK:
                    case DM:
                    case NOP:
                    case EOR:
                    case ABORT:
                    case SUSP:
                    case xEOF:
                        /* Single-byte commands - ignore */
                        ts->state = TS_DATA;
                        break;
                    default:
                        /* Unknown command - ignore */
                        ts->state = TS_DATA;
                        break;
                }
                break;
                
            case TS_WILL:
            case TS_WONT:
            case TS_DO:
            case TS_DONT:
                /* Option negotiation */
                handle_telnet_option(ts, fd, 
                    (ts->state == TS_WILL) ? WILL :
                    (ts->state == TS_WONT) ? WONT :
                    (ts->state == TS_DO) ? DO : DONT, c);
                ts->state = TS_DATA;
                break;
                
            case TS_SB:
                /* Sub-negotiation data */
                if (c == IAC) {
                    ts->state = TS_SE;
                } else if (ts->sb_len < sizeof(ts->sb_buf) - 1) {
                    ts->sb_buf[ts->sb_len++] = c;
                }
                break;
                
            case TS_SE:
                if (c == SE) {
                    /* End of sub-negotiation - process it */
                    if (ts->sb_len > 0) {
                        unsigned char option = ts->sb_buf[0];
                        /* Handle specific sub-negotiations if needed */
                        (void)option; /* Suppress unused warning for now */
                    }
                } else if (c == IAC) {
                    /* Escaped IAC in sub-negotiation */
                    if (ts->sb_len < sizeof(ts->sb_buf) - 1) {
                        ts->sb_buf[ts->sb_len++] = IAC;
                    }
                } else {
                    /* Continue sub-negotiation */
                    if (ts->sb_len < sizeof(ts->sb_buf) - 1) {
                        ts->sb_buf[ts->sb_len++] = c;
                    }
                }
                ts->state = (c == SE) ? TS_DATA : TS_SB;
                break;
        }
    }
    
    return output_len;
}

/* Send initial telnet negotiations */
static void send_initial_negotiations(int fd) {
    /* Request client to suppress go-ahead */
    send_telnet_cmd(fd, DO, TELOPT_SGA);
    
    /* Tell client we will echo */
    send_telnet_cmd(fd, WILL, TELOPT_ECHO);
    
    /* Request binary mode for clean 8-bit data */
    send_telnet_cmd(fd, DO, TELOPT_BINARY);
    send_telnet_cmd(fd, WILL, TELOPT_BINARY);
    
    /* Note: We don't request TTYPE or NAWS here because the BBS */
    /* does its own terminal detection using VT100 escape sequences */
}

/* Parse command line arguments in simplified format */
static int parse_telnetd_args(int argc, char *argv[], char **client_path, 
                             char **protocol, char **ip, char **nodeid) {
    /* Simple format: photonbbs-tty -L client_path protocol ip nodeid */
    if (argc == 6 && strcmp(argv[1], "-L") == 0) {
        *client_path = argv[2];
        *protocol = argv[3];
        *ip = argv[4];
        *nodeid = argv[5];
        return 1;
    }
    return 0; /* Failed to parse */
}

/* Validate arguments to prevent injection */
static int validate_arg(const char *arg) {
    if (!arg || strlen(arg) == 0 || strlen(arg) >= MAX_ARG_LEN) {
        return 0;
    }
    /* Allow alphanumeric, dots, slashes, hyphens, underscores for paths/IPs */
    for (const char *p = arg; *p; p++) {
        if (!isalnum(*p) && *p != '.' && *p != '/' && *p != '-' && 
            *p != '_' && *p != ':') {
            return 0;
        }
    }
    return 1;
}

/* Main execution: create PTY and run PhotonBBS client */
static int run_photonbbs_client(const char *client_path, const char *protocol, 
                               const char *ip, const char *nodeid) {
    int pty_master, pty_slave;
    pid_t child_pid;
    
    /* Initialize hex logging */
    init_hex_log();
    
    /* Validate all arguments */
    if (!validate_arg(client_path) || !validate_arg(protocol) || 
        !validate_arg(ip) || !validate_arg(nodeid)) {
        syslog(LOG_ERR, "Invalid arguments provided");
        return 1;
    }
    
    /* Check if client exists and is executable */
    if (access(client_path, X_OK) != 0) {
        syslog(LOG_ERR, "PhotonBBS client not found or not executable: %s", client_path);
        return 1;
    }
    
    /* Create PTY pair */
    if (openpty(&pty_master, &pty_slave, NULL, NULL, NULL) < 0) {
        syslog(LOG_ERR, "Failed to create PTY: %s", strerror(errno));
        return 1;
    }
    
    /* Fork to run the client */
    child_pid = fork();
    if (child_pid < 0) {
        syslog(LOG_ERR, "Fork failed: %s", strerror(errno));
        close(pty_master);
        close(pty_slave);
        return 1;
    }
    
    if (child_pid == 0) {
        /* Child process - set up TTY and exec PhotonBBS client */
        close(pty_master);
        
        /* Create new session */
        if (setsid() < 0) {
            syslog(LOG_ERR, "setsid failed: %s", strerror(errno));
            exit(1);
        }
        
        /* Set controlling TTY */
        if (ioctl(pty_slave, TIOCSCTTY, 0) < 0) {
            syslog(LOG_ERR, "TIOCSCTTY failed: %s", strerror(errno));
            exit(1);
        }
        
        /* Redirect stdin/stdout/stderr to PTY */
        dup2(pty_slave, STDIN_FILENO);
        dup2(pty_slave, STDOUT_FILENO);
        dup2(pty_slave, STDERR_FILENO);
        close(pty_slave);
        
        /* Set environment variables that PhotonBBS client expects */
        setenv("TERM", "ansi", 1);
        setenv("HOME", "/opt/photonbbs", 1);
        
        /* Execute PhotonBBS client with proper arguments */
        execl(client_path, client_path, protocol, ip, nodeid, (char *)NULL);
        
        /* If we get here, exec failed */
        syslog(LOG_ERR, "Failed to exec PhotonBBS client: %s", strerror(errno));
        exit(1);
    } else {
        /* Parent process - bridge I/O between stdin/stdout and PTY with telnet filtering */
        close(pty_slave);
        
        /* Set up SIGCHLD handler for child process reaping */
        struct sigaction sa;
        sa.sa_handler = sigchld_handler;
        sigemptyset(&sa.sa_mask);
        sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;
        if (sigaction(SIGCHLD, &sa, NULL) < 0) {
            syslog(LOG_ERR, "Failed to set SIGCHLD handler: %s", strerror(errno));
            close(pty_master);
            kill(child_pid, SIGTERM);
            return 1;
        }
        
        /* Initialize telnet state machine */
        struct telnet_state_machine telnet_state;
        init_telnet_state(&telnet_state);
        
        /* Send initial telnet negotiations */
        send_initial_negotiations(STDOUT_FILENO);
        
        fd_set read_fds;
        char input_buffer[BUFFER_SIZE];
        char output_buffer[BUFFER_SIZE];
        char pty_buffer[BUFFER_SIZE];
        int max_fd = (STDIN_FILENO > pty_master) ? STDIN_FILENO : pty_master;
        max_fd = (STDOUT_FILENO > max_fd) ? STDOUT_FILENO : max_fd;
        
        while (!child_exited) {
            FD_ZERO(&read_fds);
            FD_SET(STDIN_FILENO, &read_fds);
            FD_SET(pty_master, &read_fds);
            
            /* Use a timeout to periodically check child status */
            struct timeval timeout;
            timeout.tv_sec = 1;
            timeout.tv_usec = 0;
            
            int select_result = select(max_fd + 1, &read_fds, NULL, NULL, &timeout);
            if (select_result < 0) {
                if (errno != EINTR) {
                    syslog(LOG_ERR, "Select failed: %s", strerror(errno));
                    break;
                }
                continue;
            }
            
            /* Check if child exited */
            if (child_exited) {
                syslog(LOG_INFO, "Child process exited, terminating I/O bridge");
                break;
            }
            
            /* Handle timeout - continue loop to check child status */
            if (select_result == 0) {
                continue;
            }
            
            /* Data from stdin (telnet client) to PTY (PhotonBBS) */
            if (FD_ISSET(STDIN_FILENO, &read_fds)) {
                ssize_t n = read(STDIN_FILENO, input_buffer, sizeof(input_buffer));
                if (n <= 0) {
                    syslog(LOG_INFO, "Stdin closed, terminating session");
                    break; /* stdin closed */
                }
                hex_log_data("FROM_CLIENT", (unsigned char*)input_buffer, n);
                
                /* Process telnet protocol and filter out commands */
                int clean_len = process_telnet_input(&telnet_state, STDOUT_FILENO,
                                                   (unsigned char*)input_buffer, n,
                                                   (unsigned char*)output_buffer, 
                                                   sizeof(output_buffer));
                
                /* Send clean data to PhotonBBS */
                if (clean_len > 0) {
                    hex_log_data("TO_BBS", (unsigned char*)output_buffer, clean_len);
                    if (write(pty_master, output_buffer, clean_len) < 0) {
                        syslog(LOG_INFO, "PTY write failed, terminating session");
                        break;
                    }
                }
            }
            
            /* Data from PTY (PhotonBBS) to stdout (telnet client) */
            if (FD_ISSET(pty_master, &read_fds)) {
                ssize_t n = read(pty_master, pty_buffer, sizeof(pty_buffer));
                hex_log_data("FROM_BBS", (unsigned char*)pty_buffer, n);
                if (n <= 0) {
                    syslog(LOG_INFO, "PTY closed, terminating session");
                    break; /* PTY closed */
                }
                
                /* Send PhotonBBS output directly to client */
                /* In binary mode, no additional telnet processing needed for output */
                if (write(STDOUT_FILENO, pty_buffer, n) < 0) {
                    syslog(LOG_INFO, "Stdout write failed, terminating session");
                    break;
                }
            }
        }
        
        /* Cleanup */
        close(pty_master);
        
        /* If child hasn't exited yet, terminate it gracefully */
        if (!child_exited) {
            syslog(LOG_INFO, "Terminating child process %d", child_pid);
            kill(child_pid, SIGTERM);
            
            /* Wait a bit for graceful exit */
            sleep(1);
            
            /* Force kill if still running */
            if (!child_exited) {
                kill(child_pid, SIGKILL);
                syslog(LOG_WARNING, "Force killed child process %d", child_pid);
            }
        }
        
        /* Final reap - make sure child is cleaned up */
        int status;
        pid_t result = waitpid(child_pid, &status, WNOHANG);
        if (result > 0) {
            syslog(LOG_INFO, "Final reap of child process %d successful", child_pid);
        } else if (result == 0) {
            /* Child still running - wait for it */
            waitpid(child_pid, &status, 0);
            syslog(LOG_INFO, "Waited for child process %d to exit", child_pid);
        }
        
        return WEXITSTATUS(status);
    }
}

int main(int argc, char *argv[]) {
    char *client_path, *protocol, *ip, *nodeid;
    
    /* Initialize syslog */
    openlog("photonbbs-tty", LOG_PID | LOG_CONS, LOG_DAEMON);
    
    /* Parse command line arguments in simplified format */
    if (!parse_telnetd_args(argc, argv, &client_path, &protocol, &ip, &nodeid)) {
        syslog(LOG_ERR, "Failed to parse command line arguments");
        fprintf(stderr, "Usage: %s -L client_path protocol ip nodeid\n", argv[0]);
        exit(1);
    }
    
    if (!client_path) {
        syslog(LOG_ERR, "No client path specified");
        exit(1);
    }
    
    
    /* Run the PhotonBBS client */
    int result = run_photonbbs_client(client_path, protocol, ip, nodeid);
    
    syslog(LOG_INFO, "PhotonBBS TTY session ended");
    closelog();
    
    return result;
}
