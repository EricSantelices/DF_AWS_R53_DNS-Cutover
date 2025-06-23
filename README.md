# DF_AWS_R53_DNS-Cutover

create a file called `domains.csv` add your domains to this file one per line.

run `update_r53_records.sh` to move the domains to the on-prem servers

run `rollback_r53_records.sh` to roll them back to AWS

to avoid being throttled upload your files to an AWS cloudshell and execute from the shell
