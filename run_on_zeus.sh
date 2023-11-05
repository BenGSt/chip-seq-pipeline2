#!/usr/bin/env bash
#set -e # Stop on error
ENCD_CHIP_DIR=/home/s.benjamin/bioinformatics_software/encd_chip_seq_pipeline2_bengst

main() {
  arg_parse "$@"
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

write_bakend_conf(){
  echo "Writing backend.conf"
  cp $ENCD_CHIP_DIR/bengst_zeus.cromwell.backend.conf ./zeus.backend.conf
  sed -i "s|\"/utemp/s.benjamin/cromwell-executions\"|$PWD|" ./zeus.backend.conf
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