#!/usr/bin/env bash
#set -e # Stop on error
ENCD_CHIP_DIR=/home/s.benjamin/bioinformatics_software/encode_pipelines/chip_seq_pipeline2_bengst
CROMWELL_DIR=/home/s.benjamin/bioinformatics_software/encode_pipelines/cromwell_and_caper_conf
# CROMWELL_DIR can be created by running "caper init pbs" and copying the contents of ~/.caper .
# a line "pbs-queue=zeus_new_q" needs to be added to default.conf and it's name changed to zeus_caper.conf
#TODO: use a release of the pipeline rather than the dev version from github?

main() {
  arg_parse "$@"
  config_caper
  write_bakend_conf
  source /home/s.benjamin/other_software/conda/bin/activate caper
  caper hpc submit $ENCD_CHIP_DIR/chip.wdl \
    -i $input_json \
    --conda \
    --leader-job-name $lead_job_name \
    --local-loc-dir $PWD \
    --local-out-dir $PWD \
    --backend-file $(realpath ./zeus.backend.conf)
}


config_caper(){
  #check if ~/.caper exists
  if [ ! -d ~/.caper ]; then
    echo "Creating ~/.caper and symlinking cromwell and woomtools"
    mkdir ~/.caper
    womtool=$(basename $CROMWELL_DIR/womtool-*.jar)
    cromwell=$(basename $CROMWELL_DIR/cromwell-*.jar)
    ln -s $CROMWELL_DIR/zeus_caper.conf ~/.caper/default.conf
    ln -s $CROMWELL_DIR/$womtool ~/.caper/$womtool
    ln -s $CROMWELL_DIR/$cromwell ~/.caper/$cromwell
  else
    echo "~/.caper already exists for user $USER"
    echo "If you are uable to run the pipeline, please delete ~/.caper and rerun this script"
    echo
  fi
  # bengst 6.11.23: since from what I can tell only java 8 is available on zeus, I downloaded openjdk 21 and will add it to path
  # check if the addition of java to the path is already in ~/.bashrc, if not add it. This is needed because caper
  # sends the leader job that runs cromwell as the user and initialises the shell using ~/.bashrc
  if ! grep -q "export PATH=/home/s.benjamin/other_software/jdk-21.0.1/bin:\$PATH" ~/.bashrc; then
    echo "Adding openjdk21 bin to PATH in ~/.bashrc"
    echo "export PATH=/home/s.benjamin/other_software/jdk-21.0.1/bin:\$PATH" >> ~/.bashrc
  fi

}


write_bakend_conf(){
  echo "Writing backend.conf"
  cp $ENCD_CHIP_DIR/bengst_zeus.cromwell.backend.conf ./zeus.backend.conf
  sed -i "s|/utemp/s.benjamin/cromwell-executions|$PWD|" ./zeus.backend.conf
}

arg_parse() {
  if [ $# -lt 1 ]; then
    echo "Usage: encd_chip <input_json> [lead_job_name]"
    exit 1
  fi
  input_json=$(realpath $1)
  if [ $# -lt 2 ]; then
    lead_job_name=$(jq -r '."chip.title"' $input_json | tr -d '~/.#?*[];&<>|!$' | tr -s '[:space:]' '_' | sed 's/_$//')
  else
    lead_job_name=$2
  fi
}

main "$@"