# clone our tutorial code
git clone https://github.com/bumic/BostonHacks2020Workshop.git
cd BostonHacks2020Workshop

# load modules (only applicable if you're using BU's Shared Computing Cluster)
# You will need to install java and python on your machine.
module load openjdk/11.0.2
module load python3/3.7.7
module load tensorflow/2.1.0
module load pytorch/1.6.0

# use python virtual environment for best practice
virtualenv venv
source venv/bin/activate

# install torchserve
pip install torchserve torch-model-archiver

# clone TorchServe repo
git clone https://github.com/pytorch/serve.git

# create model_store directory
mkdir model_store
# download densenet161 pretrained model weights
wget https://download.pytorch.org/models/densenet161-8d451a50.pth
# archive the model weights to the model_store directory
torch-model-archiver --model-name densenet161 --version 1.0 --model-file ./serve/examples/image_classifier/densenet_161/model.py --serialized-file densenet161-8d451a50.pth --export-path model_store --extra-files ./serve/examples/image_classifier/index_to_name.json --handler image_classifier

# start TorchServe
torchserve --start --ncs --model-store model_store --models densenet161.mar

# In a new window, try to use the API
# Download an example image
curl -O https://raw.githubusercontent.com/pytorch/serve/master/docs/images/kitten_small.jpg
# Classify the image with a POST request
curl http://127.0.0.1:8080/predictions/densenet161 -T kitten_small.jpg

# Let's do the same thing in python
module load python3/3.7.7
# run out example app code
python example_app.py

# stop TorchServe
torchserve --stop
