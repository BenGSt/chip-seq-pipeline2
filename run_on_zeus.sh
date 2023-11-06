#!/usr/bin/env bash
#set -e # Stop on error
ENCD_CHIP_DIR=/home/s.benjamin/bioinformatics_software/encode_pipelines/chip_seq_pipeline2_bengst
CROMWELL_DIR=/home/s.benjamin/bioinformatics_software/encode_pipelines/cromwell_and_caper_conf

main() {
  arg_parse "$@"
  create_caper_home
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


create_caper_home(){
  #check if ~/.caper exists
  if [ ! -d ~/.caper ]; then
    echo "Creating ~/.caper and symlinking cromwell and woomtools"
    mkdir ~/.caper
    woomtools=$(ls $CROMWELL_DIR/woomtools-*.jar)
    cromwell=$(ls $CROMWELL_DIR/cromwell-*.jar)
    ln -s $ENCD_CHIP_DIR/zeus_default.conf default.conf
    ln -s $CROMWELL_DIR/$woomtools $woomtools
    ln -s $CROMWELL_DIR/$cromwell $cromwell
  else
    echo "~/.caper already exists for user $USER"
    echo "If you are uable to run the pipeline, please delete ~/.caper and rerun this script"
    echo
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