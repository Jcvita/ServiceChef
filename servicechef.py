import ansible_runner
import os, sys

def main():
    #if the first arg is 'create' in any case, then the following args are saved to variables
    host = sys.argv[1]
    
    #if the host is not a directory in the 'inventory' directory, then it is created
    if not os.path.isdir("inventory/" + host):
        # ask the user if they want to create a new host entry
        print("Host entry for " + host + " does not exist. Would you like to create it? (y/n)")
        if input().lower() == "y":
            os.mkdir("inventory/" + host)
            #create another directory for subnets, a file that is named after the host, and a file called 'templates.yaml'
            os.mkdir("inventory/" + host + "/subnet")
            with open("inventory/" + host + "/" + host, "w") as f:
                #read the proxmox host, port, username, and password from the user
                proxhost = input("Enter the proxmox host: ")
                port = input("Enter the proxmox port: ")
                user = input("Enter the proxmox user: ")
                passw = input("Enter the proxmox password: ")
                node = input("Enter the proxmox node: ")
                
                inv = f"""[{host}]
                {host} ansible_host={proxhost} ansible_port={port} ansible_user={user} ansible_password={passw} ansible_connection=proxmox node={node}
                """
                
    if sys.argv[2].lower() == "create":
        templates = sys.argv[2:]
        

if __name__ == "__main__":
    main()