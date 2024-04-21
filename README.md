# Ubuntu Container for Data Science
This repo includes scripts for building an Ubuntu Docker container for data science. It includes commonly used data science and machine learning tools and packages e.g., R, Conda, Python, Spark, Ollama, etc. The details can be found in `install_bash_packages.sh`.

You can commit the container as an image, so you can pull the image to have a new Ubuntu environment when you want to test something out.

Support both Arm64 and X64 CPU architecture.

## Getting Started
```shell
# make sure Docker is on
git clone --depth 1 https://github.com/maxleungtszchun/Ubuntu-for-Data-Science.git
cd ./Ubuntu-for-Data-Science
chmod +x ./ubuntu4ds.sh
./ubuntu4ds.sh
```

After inputting the above code to your terminal, you only need to choose your username and password and wait for the scripts to complete.

## Container to Image
```shell
sudo docker commit ubuntu4ds ubuntu4ds_image
```

## Example
```shell
sudo docker run -it -w /home/<your-username> --name ubuntu4ds ubuntu4ds_image su <your-username>

# use Ollama to chat with LLM (Llama3)
llama3
```
