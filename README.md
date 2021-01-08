# scripts
Scripts for different purposes

## Quick-start

Just take a command to get all these scripts:

```sh
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/minhluantran017/scripts/master/quickstart.sh)"
```

Now feel free to investigate!

## Prerequisite

You should have these tool to run my scripts:
* Git
* cURL
* (TBD...)

## Configuration instruction

After running the `quickstart.sh` script above, you now can jump to below items:

#### Jenkins

You should have a Jenkins `config` file (same as the AWS config file if you are familiar with)
under `$HOME/.jenkins` directory:

```ini
[default]
JENKINS_URL=https://jenkins.example.com
JENKINS_USER=tommy
JENKINS_API_TOKEN=1a2b3c4d5e6f
```
