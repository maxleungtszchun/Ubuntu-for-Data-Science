# Ubuntu Container for Data Science
This repo includes scripts for building an Ubuntu Docker container for data science. It includes commonly used data science and machine learning tools. The details can be found in `install_bash_packages.sh`.

You can commit the container as an image, so you can pull the image to have a new Ubuntu environment when you want to test something out.

Support both Arm64 and X64 CPU architecture.

## Getting Started
```shell
# make sure Docker is on
git clone --depth 1 https://github.com/maxleungtszchun/Ubuntu-for-Data-Science.git
cd ./Ubuntu-for-Data-Science
chmod +x ./ubuntu4ds.sh
sudo ./ubuntu4ds.sh
```

After inputting the above code to your terminal, you only need to choose your username and password and wait for the scripts to complete.

## Container to Image
```shell
sudo docker commit ubuntu4ds ubuntu4ds_image
```

## Example
```shell
sudo docker run -it -p 8080:8080 -p 7860:7860 -w /home/<your-username> --name ubuntu4ds ubuntu4ds_image su <your-username>

curl -fsSL https://storage.googleapis.com/generativeai-downloads/images/cake.jpg -o ~/cake.jpg
ollama run llama3.2-vision "is it a cake? /home/user/cake.jpg"

echo 'what is llama3.2' | fabric -sp ai

cat > ~/ModelFile <<-'EOF'
	FROM llama3.2-vision
	PARAMETER num_ctx 15000
	PARAMETER temperature 0
EOF
ollama create llama3.2-vision_15000 -f ~/ModelFile

~/miniforge3/envs/docling/bin/docling --from pdf --to text --output ~ https://upload.wikimedia.org/wikipedia/commons/1/1a/HKFactSheet_BasicLaw_122014.pdf
cat ~/HKFactSheet_BasicLaw_122014.txt | fabric --model llama3.2-vision_15000:latest -sp extract_wisdom

echo 'Bachelor’s degree in Mathematics, Information Engineering, Statistics, Marketing or other relevant disciplines
3+ years of relevant work experience in a similar function from a sizable company. Experience and interest in the travel and hospitality industry will be an advantage
Proficiency in scripting languages (SAS, SQL) is a must
Proficiency in data visualization tools (especially Tableau) is a must
Ability to write queries / programs and experience with R or Python will be an advantage
Experience with statistics modelling, such as decision tree, regression, clustering etc. will also be an advantage
A team player with strong time management skills and great attention to detail' | fabric --model llama3.2-vision_15000:latest -sp extract_skills

# you can also visit http://localhost:8080 to use Open Webui
# you can even use Stable Diffusion model in Open Webui by:
# setting -> admin settings -> images -> image generation engine = automatic1111 -> Base URL = http://localhost:7860 -> turn on Image Generation (Experimental) -> save
```

## Pull Image directly from Docker Hub
You can pull the image directly from Docker Hub without building.

```shell
# for Arm64 CPU
sudo docker run -it -p 8080:8080 -p 7860:7860 -w /home/user --name ubuntu4ds "maxleung414/ubuntu4ds:latest" su user

# for X64 CPU
sudo docker run -it -p 8080:8080 -p 7860:7860 -w /home/user --name ubuntu4ds "ml414/ubuntu4ds:latest" su user

```