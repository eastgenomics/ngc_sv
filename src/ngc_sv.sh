#!/bin/bash
# ngc_sv 0.1

set -exo pipefail

main() {

    echo "Value of input_vcf_files: '${input_vcf_files[@]}'"
    echo "Value of input_family_file: '$input_family_file'"
    echo "Value of input_manifest_file: '$input_manifest_file'"

    # download input files
    dx download "$input_family_file"

    dx download "$input_manifest_file"

    #download vcf files
    for i in "${!input_vcf_files[@]}"
    do
        dx download "${input_vcf_files[$i]}"
    done

    # install python3.8
    gunzip Miniconda3-latest-Linux-x86_64.sh.gz

    bash ~/Miniconda3-latest-Linux-x86_64.sh -b

    # install required python packages from local packages dir
    echo "Installing python packages"
    cd packages
    ~/miniconda3/bin/pip install -q numpy-* xmltodict-*
    cd ~

    echo "Finished packages installation."

    # output 
    for i in "${!output_file[@]}"; do
        dx-jobutil-add-output output_file "${output_file[$i]}" --class=array:file
    done
}
