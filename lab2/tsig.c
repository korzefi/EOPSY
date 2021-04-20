//PROCESSES AND SIGNALS
//
//[] 1. Write a program in C with the name tsig, which tests synchronization  mechanisms and signals. Use the following system functions: fork(), wait(),  signal() or sigaction() and kill(). The program should run the algorithm   from the section 2 with additional modifications from the section 3.
//
//[] 2. Processes' algorithms without signal handlers
//
//  The main (parent) process algorithm
//
//1. Create NUM_CHILD child processes, where NUM_CHILD is defined in the  program, use the fork() function. Insert one second delays between  consecutive fork() calls.
//
//2. Check whether each of the child processes has been correctly created. If  not, print an appropriate message, send to all already created child  processes SIGTERM signal and finish with the exit code 1.
//3. Print a message about creation of all child processes.
//4. Call in a loop the wait() function, until receiving from the system  information that there are no more processes to be synchronized with the  parent one. Print a message that there are no more child processes. In this  loop do count child processes terminations and, at the very end of the  parent process, print a message with the number of just received child  processes exit codes.
//
//The child process algorithm
//
//  1. Print process identifier of the parent process
//
//2. Sleep for 10 seconds
//
//3. Print a message about execution completion  At this stage check whether your program works correctly. Only if it works  correctly, continue with the tasks from the next section.
//
//[] 3. Some modifications related to signal handlers
//In the parent process
//a. force ignoring of all signals with the signal() (or sigaction()) but  after that at once restore the default handler for SIGCHLD signal
//b. set your own keyboard interrupt signal handler (symbol of this interrupt:  SIGINT)
//c. the handler should print out info about receiving the keyboard interrupt  and set some mark (global variable) which will notify about the fact of  keyboard interrupt occurance
//d. modify the main program in the following way: between the two consequtive  creations of new processes check the mark which may be set by the keyboard  interrupt handler. If the mark is set the parent process should signal all  just created processes with the SIGTERM and, instead of printing the message  about creation, print out a message about interrupt of the creation process.  After that, the process should continue with wait()'s loop as before.
//e. at the very end of the main process, the old service handlers of all  signals should be restored.
//In the child process
//a. set to ignore handling of the keyboard interrupt signal
//b. set your own handler of the SIGTERM signal, which will only print a  message of the termination of this process.
//
//[] 4. Additional remarks
//a. two versions of the program are expected to be implemented, without and  with signals (without changes from the section 3 and with them). The code  should be in one source file and the version of compilation should be drived  by the definition or by the lack of definition of the WITH_SIGNALS  preprocessor symbol.
//b. each printed message should start with the process identifier in the form  child[PID] and in case of the parent process, parent[PID], e.g.:
//parent[123]: sending SIGTERM signal
//child[125]:  received SIGTERM signal, terminating
//
//[] 5. Hints
//a. look at the following manual pages: fork(), wait(), signal(),  sigaction(), kill(), getpid(), getppid(), sleep()
//b. look at the content of the <signal.h> file
//c. use for complex signal handling settings the symbol NSIG defined in   standard include files
//d. use stty command to get to know which keypress generates an interrupt  from the keyboard (SIGINT) under your current shell configuration
//


#include <stdio.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>

// ctrl+c generates an interrupt (SIGINT)

#define WITH_SIGNALS

#define NUM_CHILD 10
static pid_t children[NUM_CHILD];
int mark = 0;

#ifdef WITH_SIGNALS
void keyboard_interrupt_handler(int sig) {
    printf("Parent[%d], received SIGINT keyboard interrupt\n", getpid());
    mark = 1;
}

void sigterm_handler(int sig) {
    printf("Child[%d], received SIGTERM interrupt, terminating\n", getpid());
}
#endif

void child_process() {
    #ifdef WITH_SIGNALS
    signal(SIGINT, SIG_IGN); // ingore handling of the keyboard interrupt signal
    signal(SIGTERM, sigterm_handler); //
    #endif
    printf("Child[%d], parent[%d]\n", getpid(), getppid());
    sleep(10);
    printf("Child[%d], parent[%d], execution of child completed\n", getpid(), getppid());
}

void kill_children(int created_num) {
    for (int i=0; i<created_num; i++) {
        kill(children[i], SIGTERM);
    }
}

void successive_forks() {
    #ifdef WITH_SIGNALS
    for(int i = 1; i < NSIG; i++) {
        signal(i, SIG_IGN);     // ignoring all signals
    }
    signal(SIGCHLD, SIG_DFL);   // restore: if some of children processes finished working, SIGCHLD signal basically handled
    signal(SIGINT, keyboard_interrupt_handler);
    #endif
    for(int i=0; i<NUM_CHILD; i++) {
        if (mark == 1) {
            printf("Parent[%d], creation child process interrupted\n", getpid());
            int size = i;
            kill_children(size);
            break;
        }
        pid_t created = fork();
        if (created < 0) {
            printf("Child[%d] has not beed created sucessfully, killing others\n", created);
            int size = i+1;
            kill_children(size);
            exit(1);
        }
        else if (created == 0) {
            child_process();
            exit(0);
        }
        else {
            children[i] = created;
        }
        sleep(1);
    }
}

void wait_function() {
    int status;
    pid_t pid;
    int proper_counter = 0;
    int wrong_counter = 0;

    while(1) {
        pid = wait(&status);
        if (pid < 0) {
            break;
        }
        if (WIFEXITED(status)) {
            printf("Child[%d], Parent[%d]: Exit status: %d\n", pid, getpid(), WEXITSTATUS(status));
            proper_counter++;
        }
        else {
            wrong_counter++;
        }
    }
    
    printf("There are no more child processes\n");
    printf("Child processes with exit code 0: %d\n", proper_counter);
    printf("Child processes with exit code 1: %d\n", wrong_counter);
}

int main(int argc, const char * argv[]) {
    
    successive_forks();
    wait_function();
    
    #ifdef WITH_SIGNALS
    for(int i = 1; i < NSIG; i++){
        signal(i, SIG_DFL);
    }
    #endif

    return 0;
}
