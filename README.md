# Getting Started with TorchServe

![Architecture Diagram](https://user-images.githubusercontent.com/880376/83180095-c44cc600-a0d7-11ea-97c1-23abb4cdbe4d.jpg)

## What is TorchServe?

TorchServe is a tool to host your PyTorch models on a server for REST API calls.
TorchServe decouples your expensive PyTorch code from your application via API calls 
and allows your team to work independently of the machine learning engineer.
Read more about TorchServe at their [official github repository](https://github.com/pytorch/serve).

## [Install the Prerequisites](https://github.com/pytorch/serve#install-torchserve)

1. Install Java 11

    For Ubuntu
    ```bash
    sudo apt-get install openjdk-11-jdk
    ```
   
   For Mac
    ```bash
    brew tap AdoptOpenJDK/openjdk
    brew cask install adoptopenjdk11
    ```
   
   For Windows  
   Install from https://www.oracle.com/java/technologies/javase-jdk11-downloads.html

2. Install python pre-requisite packages

To install the requirements via `requirements.txt`, you must first clone the TorchServe repository. 
Alternatively, you can install PyTorch independently and then do a pip install for `torchserve` and `torch-model-archiver`. (recommended)

 - For CPU or GPU-Cuda 10.2

    ```bash
    pip install -U -r requirements.txt
    ```
 - For GPU with Cuda 10.1

    ```bash
    pip install -U -r requirements_gpu.txt -f https://download.pytorch.org/whl/torch_stable.html
   ```

3. Install torchserve and torch-model-archiver

    For [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install)
    ```
    conda install torchserve torch-model-archiver -c pytorch
    ```
   
    For Pip
    ```
    pip install torchserve torch-model-archiver
    ```
   
   **Note:** For Conda, Python 3.8 is required to run Torchserve

Now you are ready to [package and serve models with TorchServe](#serve-a-model).

## Serve a model

This section shows a simple example of serving a model with TorchServe. To complete this example, you must have already [installed TorchServe and the model archiver](#install-with-pip).

To run this example, clone the TorchServe repository:

```bash
git clone https://github.com/pytorch/serve.git
```

Then run the following steps from the parent directory of the root of the repository.
For example, if you cloned the repository into `/home/my_path/serve`, run the steps from `/home/my_path`.

### Store a Model

To serve a model with TorchServe, first archive the model as a MAR file. You can use the model archiver to package a model.
You can also create model stores to store your archived models.

1. Create a directory to store your models.

    ```bash
    mkdir model_store
    ```

1. Download a trained model.

    ```bash
    wget https://download.pytorch.org/models/densenet161-8d451a50.pth
    ```

1. Archive the model by using the model archiver. The `extra-files` param uses fa file from the `TorchServe` repo, so update the path if necessary.

    ```bash
    torch-model-archiver --model-name densenet161 --version 1.0 --model-file ./serve/examples/image_classifier/densenet_161/model.py --serialized-file densenet161-8d451a50.pth --export-path model_store --extra-files ./serve/examples/image_classifier/index_to_name.json --handler image_classifier
    ```

For more information about the model archiver, see [Torch Model archiver for TorchServe](https://github.com/pytorch/serve/blob/master/model-archiver/README.md)

### Start TorchServe to serve the model

After you archive and store the model, use the `torchserve` command to serve the model.

```bash
torchserve --start --ncs --model-store model_store --models densenet161.mar
```

After you execute the `torchserve` command above, TorchServe runs on your host, listening for inference requests.

**Note**: If you specify model(s) when you run TorchServe, it automatically scales backend workers to the number equal to available vCPUs (if you run on a CPU instance) or to the number of available GPUs (if you run on a GPU instance). In case of powerful hosts with a lot of compute resoures (vCPUs or GPUs), this start up and autoscaling process might take considerable time. If you want to minimize TorchServe start up time you should avoid registering and scaling the model during start up time and move that to a later point by using corresponding [Management API](docs/management_api.md#register-a-model), which allows finer grain control of the resources that are allocated for any particular model).

### Get predictions from a model

To test the model server, send a request to the server's `predictions` API.

Complete the following steps:

* Open a new terminal window (other than the one running TorchServe).
* Use `curl` to download one of these [cute pictures of a kitten](https://www.google.com/search?q=cute+kitten&tbm=isch&hl=en&cr=&safe=images)
  and use the  `-o` flag to name it `kitten.jpg` for you.
* Use `curl` to send `POST` to the TorchServe `predict` endpoint with the kitten's image.

![kitten](https://github.com/pytorch/serve/blob/master/docs/images/kitten_small.jpg)

The following code completes all three steps:

```bash
curl -O https://raw.githubusercontent.com/pytorch/serve/master/docs/images/kitten_small.jpg
curl http://127.0.0.1:8080/predictions/densenet161 -T kitten_small.jpg
```

The predict endpoint returns a prediction response in JSON. It will look something like the following result:

```json
[
  {
    "tiger_cat": 0.46933549642562866
  },
  {
    "tabby": 0.4633878469467163
  },
  {
    "Egyptian_cat": 0.06456148624420166
  },
  {
    "lynx": 0.0012828214094042778
  },
  {
    "plastic_bag": 0.00023323034110944718
  }
]
```

You will see this result in the response to your `curl` call to the predict endpoint, and in the server logs in the terminal window running TorchServe. It's also being [logged locally with metrics](docs/metrics.md).

Now you've seen how easy it can be to serve a deep learning model with TorchServe! [Would you like to know more?](docs/server.md)

### Stop the running TorchServe

To stop the currently running TorchServe instance, run the following command:

```bash
torchserve --stop
```

You see output specifying that TorchServe has stopped.


### Concurrency And Number of Workers
TorchServe exposes configurations that allow the user to configure the number of worker threads on CPU and GPUs. There is an important config property that can speed up the server depending on the workload.
*Note: the following property has bigger impact under heavy workloads.*
If TorchServe is hosted on a machine with GPUs, there is a config property called `number_of_gpu` that tells the server to use a specific number of GPUs per model. In cases where we register multiple models with the server, this will apply to all the models registered. If this is set to a low value (ex: 0 or 1), it will result in under-utilization of GPUs. On the contrary, setting to a high value (>= max GPUs available on the system) results in as many workers getting spawned per model. Clearly, this will result in unnecessary contention for GPUs and can result in sub-optimal scheduling of threads to GPU.
```
ValueToSet = (Number of Hardware GPUs) / (Number of Unique Models)
```


## Quick Start with Docker
Refer [torchserve docker](https://github.com/pytorch/serve/blob/master/docker/README.md) for details.

## Learn More

* [Full documentation on TorchServe](https://github.com/pytorch/serve/blob/master/docs/README.md)
* [Manage models API](https://github.com/pytorch/serve/blob/master/docs/management_api.md)
* [Inference API](https://github.com/pytorch/serve/blob/master/docs/inference_api.md)
* [Package models for use with TorchServe](https://github.com/pytorch/serve/blob/master/model-archiver/README.md)
* [TorchServe model zoo for pre-trained and pre-packaged models-archives](https://github.com/pytorch/serve/blob/master/docs/model_zoo.md)


