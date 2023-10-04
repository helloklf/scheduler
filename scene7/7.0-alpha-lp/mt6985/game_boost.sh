metis=/sys/module/metis/parameters
for file in $metis/*enable*; do
  echo 0 > $file
done
if [[ -d $metis ]]; then
  chmod -R 444 $metis
fi
