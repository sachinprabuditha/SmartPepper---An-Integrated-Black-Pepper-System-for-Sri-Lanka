import paramiko
import sys

host = '135.222.208.145'
user = 'Sliit'
pwd = 'Sliit@123456'
port = 22
file_path = 'deploy.zip'
remote_path = '/home/Sliit/deploy.zip'

print("Connecting SSH...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
try:
    ssh.connect(host, port, user, pwd, timeout=30)
    print("Uploading file via SFTP...")
    sftp = ssh.open_sftp()
    sftp.put(file_path, remote_path)
    sftp.close()
    
    print("Executing deployment commands...")
    commands = [
        f"echo '{pwd}' | sudo -S apt-get update",
        f"echo '{pwd}' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y docker.io docker-compose unzip",
        f"echo '{pwd}' | sudo -S systemctl enable docker",
        f"echo '{pwd}' | sudo -S systemctl start docker",
        f"echo '{pwd}' | sudo -S usermod -aG docker {user}",
        "mkdir -p deploy_folder",
        "unzip -o deploy.zip -d deploy_folder > /dev/null",
        f"cd deploy_folder && echo '{pwd}' | sudo -S docker-compose up -d --build"
    ]
    for cmd in commands:
        print(f"Running: {cmd.split('|')[1].strip() if '|' in cmd else cmd}", flush=True)
        stdin, stdout, stderr = ssh.exec_command(cmd, get_pty=True)
        exit_status = stdout.channel.recv_exit_status()
        out = stdout.read().decode().replace(pwd, '***')
        err = stderr.read().decode().replace(pwd, '***')
        if out: print(out, flush=True)
        if err: print("ERR:", err, flush=True)
        if exit_status != 0:
            print(f"Command failed with exit code {exit_status}", flush=True)
            break
finally:
    ssh.close()
print("Done!", flush=True)
