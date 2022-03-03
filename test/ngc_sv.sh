#!/bin/bash
# ngc_sv

set -exo pipefail

main() {

    echo "Value of input_vcf_files: '${input_vcf_files[@]}'"
    echo "Value of input_family_file: '$input_family_file'"
    echo "Value of input_manifest_file: '$input_manifest_file'"
    echo "Value of input_sv_bundle: '$input_sv_bundle'"
    echo "Value of input_sv_env: '$input_sv_env'"
    
    time dx-download-all-inputs --parallel
    
    mkdir -p out/outfiles
    
    #Permissions to write to /home/dnanexus
    chmod a+rwx /home/dnanexus

    #move all downloaded vcf files into folder: /sv/demo/examples/samples
    find ~/in/input_sv_env -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/
    
    find ~/in/input_sv_bundle -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/

    # unpack sv pipeline bundle
    tar -xzf /home/dnanexus/sv.tar.gz

    find ~/in/input_vcf_files -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/samples

    find ~/in/input_family_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    find ~/in/input_manifest_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    echo "files are copied"

    #install conda, create, run env
    wget https://repo.anaconda.com/miniconda/Miniconda-latest-Linux-x86_64.sh \
    && chmod +x Miniconda-latest-Linux-x86_64.sh \
    && bash Miniconda-latest-Linux-x86_64.sh -b
    
    conda env create -f /home/dnanexus/sv_env.yml
    
    conda activate ngc_sv

    #Run sv scripts
    python /home/dnanexus/sv/processSV.py -m /home/dnanexus/sv/demo/examples/manifest.txt -a /home/dnanexus/sv/CONFIG/Analysis.xml -w /home/dnanexus/sv/demo/examples/ -e vcfanno_demo -f /home/dnanexus/sv/demo/examples/family_id.txt -r grch38 -l F -p 20220301

    sh /home/dnanexus/sv/demo/examples/20220301/tmp_binaries/NGC001_01.vcfanno_demo.sh

    conda deactivate
    
    # copy the specifica output dir back to the output dir
    cp -r /home/dnanexus/sv/demo/examples/20220301/tmp_data/* /home/dnanexus/out/outfiles/

    # output 
    dx-upload-all-outputs --parallel
}
