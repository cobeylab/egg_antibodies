library(dplyr)
library(tidyr)
library(yaml)
library(readr)
library(stringr)
library(ggplot2)
library(cowplot)
theme_set(theme_cowplot())

yaml_file_paths <- list.files('../results/', pattern = 'yaml', full.names = T)

# Processes sequences ('events' in the yaml_object)
process_sequence <- function(sequence){
  row <- tibble(
    sequence_id = sequence$unique_ids,
    length_vd_insertion = nchar(sequence$vd_insertion),
    length_dj_insertion = nchar(sequence$dj_insertion),
    total_insertions = nchar(sequence$vd_insertion) + nchar(sequence$dj_insertion),
    v_gene = sequence$v_gene,
    d_gene = sequence$d_gene,
    j_gene = sequence$j_gene,
    vd_insertion = sequence$vd_insertion,
    dj_insertion = sequence$dj_insertion,
    input_seq = sequence$input_seq
  )
  # If sequence has duplicates, add duplicate rows
  n_duplicates <- length(sequence$duplicates[[1]])
  if(n_duplicates > 0){
    duplicate_names <- sequence$duplicates[[1]]
    for(i in 1:n_duplicates){
      row <- bind_rows(row,
                       row %>% mutate(sequence_id = duplicate_names[i]))
      
    }
  }
  return(row)
  
  
}

process_partis_output <- function(yaml_file_path){
  yaml_object <- read_yaml(yaml_file_path)
  return(bind_rows(lapply(yaml_object$events, FUN = process_sequence)) %>%
           mutate(dataset = str_split(basename(yaml_file_path),'\\.')[[1]][1]))
}

processed_files <- lapply(as.list(yaml_file_paths), FUN = process_partis_output)

for(i in 1:length(processed_files)){
  file_id = str_split(basename(yaml_file_paths[i]),'\\.')[[1]][1]
  
  write_csv(processed_files[[i]],
            paste0('../results/N-insertions_', file_id,'.csv'))
}

# Quick plot
quick_plot <- bind_rows(processed_files) %>%
  select(dataset, sequence_id, length_vd_insertion, length_dj_insertion, total_insertions) %>%
  pivot_longer(cols = c('length_vd_insertion', 'length_dj_insertion', 'total_insertions')) %>%
  mutate(
    insertion_type = case_when(
      name == 'length_vd_insertion' ~ 'VD insertions',
      name == 'length_dj_insertion' ~ 'DJ insertions',
      name == 'total_insertions' ~ 'Total insertions'
    )
  ) %>%
  mutate(insertion_type = factor(insertion_type, levels = c('Total insertions',
                                                            'VD insertions',
                                                            'DJ insertions'))) %>%
  rename(n_insertions = value) %>%
  select(-name) %>%
  ggplot(aes(x = dataset, y = n_insertions)) +
  geom_boxplot(outlier.alpha = 0) +
  geom_point(size = 2, alpha = 0.5, position = position_jitter(width = 0.1, height = 0)) +
  facet_grid(.~insertion_type) +
  xlab('Data set') +
  ylab('Number of insertions')

save_plot('../results/quick_plot.pdf', quick_plot,
          base_height = 5, base_width = 12)



