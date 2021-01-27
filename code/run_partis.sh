#!/bin/bash
# Runs partis annotation for input fasta file

input_file_path=$1
file_id=$(echo o $input_file_path | grep -o '/[^/]*.fasta' | grep -o '[^/]*')

sbatch_file=run_partis_${file_id}.sbatch

output_file=../results/${file_id}.yaml

# --------------- SBATCH FILE ---------
echo '#!/bin/bash' > $sbatch_file
echo "#SBATCH --job-name=run_partis_${file_id}" >> $sbatch_file
echo "#SBATCH --output=out_err_files/run_partis_${file_id}.out" >> $sbatch_file
echo "#SBATCH --error=out_err_files/run_partis_${file_id}.err" >> $sbatch_file
echo "#SBATCH --time=200:00:00" >> $sbatch_file
echo "#SBATCH --partition=cobey" >> $sbatch_file
echo "#SBATCH --nodes=1" >> $sbatch_file
echo "#SBATCH --ntasks-per-node=16" >> $sbatch_file
echo "#SBATCH --mem-per-cpu=3000" >> $sbatch_file

echo /project2/cobey/partis/bin/partis annotate --n-procs 16 --species human --infname "$input_file_path" --outfname "$output_file" >> $sbatch_file

sbatch $sbatch_file
rm $sbatch_file
