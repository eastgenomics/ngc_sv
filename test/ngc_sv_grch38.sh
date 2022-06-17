#!/bin/bash
# ngc_sv_grch38

set -exo pipefail

main() {

    echo "Value of input_vcf_files: '${input_vcf_files[@]}'"
    echo "Value of input_family_file: '$input_family_file'"
    echo "Value of input_manifest_file: '$input_manifest_file'"
    echo "Value of input_sv_bundle: '$input_sv_bundle'"
    
    time dx-download-all-inputs --parallel
    
    mkdir -p out/outfiles
    
    #move all downloaded vcf files into folder   
    find ~/in/input_sv_bundle -type f -name "*" -print0 | xargs -0 -I {} mv {} /home/dnanexus/

    # unpack sv pipeline bundle
    tar -xzf /home/dnanexus/sv.tar.gz

    find ~/in/input_vcf_files -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/samples

    find ~/in/input_family_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    find ~/in/input_manifest_file -type f -name "*" -print0 | xargs -0 -I {} mv {} ~/sv/demo/examples/

    echo "files are copied"
    
    #install conda, create, run env
    wget https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh -O ~/anaconda3.sh

    bash ~/anaconda3.sh -b -p
    
    #source ~/.bashrc

    eval "$(/home/dnanexus/anaconda3/bin/conda shell.bash hook)"
    
    conda init

    conda deactivate

    conda config --set auto_activate_base false
    
    # create conda environment ######
    
    conda env create -f /home/dnanexus/sv/sv_env.yml

    conda env create -f /home/dnanexus/r4.yml
    
    source /home/dnanexus/anaconda3/etc/profile.d/conda.sh
    
    # activate conda env
    conda activate ngc_sv

    # run py2 sv scripts
    python /home/dnanexus/sv/processSV.py -m /home/dnanexus/sv/demo/examples/manifest.csv -a /home/dnanexus/sv/CONFIG/Analysis.ngc.xml -w /home/dnanexus/sv/demo/examples -e vcfanno_ngc -f /home/dnanexus/sv/demo/examples/family_id.txt -r grch38 -l F -p 20220610
    
    # Rename and edit r scripts
    for file in /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/*.sh
    do
        #python2 script 
        #eval "$(/home/dnanexus/miniconda/bin/conda shell.bash hook)"
        #source /home/dnanexus/anaconda3/etc/profile.d/conda.sh
        
        filename="$(basename "$file")";
        BamFileName="${filename%.*}";
        echo "BAMFILE: $BamFileName"
        
        # seperate the py2 and r code into two different shell scripts
        
        awk '{if(NR==1) print $0}' /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.sh > /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.r.sh
        
        awk '{if(NR==502) print $0}' /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.sh >> /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.r.sh

        awk '{sub(/Rscrip/,"##")}1' /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.sh > /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.new.sh
        
        bash /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.new.sh
        
        # r script
        #eval "$(/home/dnanexus/anaconda3/bin/conda shell.bash hook)"
        #source /home/dnanexus/anaconda3/etc/profile.d/conda.sh
        
        # activate conda env
        conda activate r4
        
        bash /home/dnanexus/sv/demo/examples/20220610/tmp_binaries/$BamFileName.r.sh
        
        #Rscript  /home/dnanexus/sv/familyFiltering.R -v /home/dnanexus/sv/demo/examples/20220610/tmp_data/NGC00332/NGC00332_01/NGC00332_01.merged.all.0.7.overlap.fmt.bed.gz -o /home/dnanexus/sv/demo/examples/20220610/tmp_data/NGC00332/NGC00332_01/filter/ -f NGC00332 -n NGC00332_01 -p /home/dnanexus/sv/demo/examples/manifest.csv -c 0.7 -i /home/dnanexus/sv/demo/resources/curated/imprinted_genes_20200424.txt -r grch38

    done

    #copy results files to home upload dir
    cp -r /home/dnanexus/sv/demo/examples/20220610/tmp_data/* /home/dnanexus/out/outfiles/

    # upload output 
    dx-upload-all-outputs --parallel
}
