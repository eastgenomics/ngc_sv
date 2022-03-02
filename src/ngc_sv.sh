#!/bin/bash
# ngc_sv

set -exo pipefail

main() {

    echo "Value of input_vcf_files: '${input_vcf_files[@]}'"
    echo "Value of input_family_file: '$input_family_file'"
    echo "Value of input_manifest_file: '$input_manifest_file'"
    echo "Value of input_sv_bundle: '$input_sv_bundle'"
    echo "Value of sv_docker: '$sv_docker'"
    
    time dx-download-all-inputs --parallel
    
    mkdir -p out/outfiles
    
    #Permissions to write to /home/dnanexus
    chmod a+rwx /home/dnanexus

    #move all downloaded vcf files into folder: /sv/demo/examples/samples
    find ~/in/input_sv_bundle -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/
    # unpack sv pipeline bundle
    tar -xzf /home/dnanexus/sv.tar.gz

    find ~/in/input_vcf_files -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/samples

    find ~/in/input_family_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    find ~/in/input_manifest_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    echo "files are copied"

    #Load docker
    docker load -i "$sv_docker_path"

    #Run sv docker
    docker run -v /home/dnanexus:/myfiles -w /myfiles ngc_sv:v1.0

    python /myfiles/sv/processSV.py -m /myfiles/sv/demo/examples/manifest_docker.txt -a /myfiles/sv/CONFIG/Analysis_docker.xml -w /myfiles/sv/demo/examples/ -e vcfanno_demo -f /myfiles/sv/demo/examples/family_id_docker.txt -r grch38 -l F -p 20220301

    sh /myfiles/sv/demo/examples/20220301/tmp_binaries/NGC001_01.vcfanno_demo.sh

    exit
    
    # copy the specifica output dir back to the output dir
    cp -r /home/dnanexus/sv/demo/examples/20220301/tmp_data/* /home/dnanexus/out/outfiles/

    # output 
    dx-upload-all-outputs --parallel
}
