import requests

if __name__ == '__main__':
    # curl -O https://raw.githubusercontent.com/pytorch/serve/master/docs/images/kitten_small.jpg
    files = {'data': open('kitten_small.jpg', 'rb')}
    url = 'http://127.0.0.1:8080/predictions/densenet161'
    response = requests.post(url, files=files)
    print(response.json())
