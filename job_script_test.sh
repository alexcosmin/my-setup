#!/bin/sh
### General options
### –- specify queue --
#sBSUB -q gpuv100
### -- set the job Name --
#BSUB -J s173001_test_job
### -- ask for number of cores (default: 1) --
#BSUB -n 1
### -- Select the resources: 1 gpu in exclusive process mode --
#BSUB -gpu "num=1:mode=exclusive_process"
### -- set walltime limit: hh:mm --  maximum 24 hours for GPU-queues right now
#BSUB -W 1:00
# request 5GB of system-memory
#BSUB -R "rusage[mem=5GB]"
### -- set the email address --
# please uncomment the following line and put in your e-mail address,
# if you want to receive e-mail notifications on a non-default address
##BSUB -u alexvasile92@gmail.com
### -- send notification at start --
#BSUB -B
### -- send notification at completion--
#BSUB -N
### -- Specify the output and error file. %J is the job-id --
### -- -o and -e mean append, -oo and -eo mean overwrite --
#BSUB -o gpu-%J.out
#BSUB -e gpu_%J.err
# -- end of LSF options --

nvidia-smi
# Load the cuda module
module load cuda/9.1

/appl/cuda/9.1/samples/bin/x86_64/linux/release/deviceQuery

# This is a test
cat >> s173001_test_job_output.txt << EOF
Whoa, this bad boy actually worked.
EOF

