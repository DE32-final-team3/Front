# 🎞️ CINEMATE

## Flutter Setup
- Refer to the [Flutter Official Website](https://docs.flutter.dev/get-started/install) for setup instructions.

## Requirements
- Create a `.env` file with the following content:
```
SERVER_IP=<fastapi, mongodb server ip>
CHAT_IP=<kafka, websocket server ip>
```

## Usage
### flutter Build
To build the web application, run the following command:
```
$ flutter build web
```
### Nginx Setup
To set up Nginx and deploy the web application:
```
# Update package list
$ sudo apt updage
# Install Nginx
$ sudo apt install nginx -y
# Copy build files to Nginx web directory
$ sudo cp -r ~/web/* /var/www/html/
# Restart Nginx to apply changes
$ sudo systemctl restart nginx
```

## Screen Example

| 00-1 Login | 00-2 Sign Up | 01-1 My Page |
|------------|--------------|--------------|
| ![Login](https://github.com/user-attachments/assets/ba459cba-4311-47f0-9d3a-7a1073f92ef8) | ![Sign Up](https://github.com/user-attachments/assets/f229d547-5925-442b-95d5-fbb601d28be0) | ![My Page](https://github.com/user-attachments/assets/efa5ae08-21b3-4333-b7e8-a31aae5fe0ae) |

| 01-2 Edit Profile | 02-1 Curation List | 02-2 Create Curation |
|-------------------|--------------------|----------------------|
| ![Edit Profile](https://github.com/user-attachments/assets/766f7180-db56-4a3d-adcd-0d6942eff36f) | ![Curation List](https://github.com/user-attachments/assets/4f01f8a1-e0f5-4651-9042-dd6ddb301441) | ![Create Curation](https://github.com/user-attachments/assets/73085070-fa7c-4802-b488-3681e2099748) |

| 02-3 Movie Search | 02-4 Selected Movie List | 03-1 Chat List |
|-------------------|--------------------------|----------------|
| ![Movie Search](https://github.com/user-attachments/assets/587264eb-c1de-4ff4-904b-8fe092d8f468) | ![Selected Movie List](https://github.com/user-attachments/assets/17d7ab1c-76a9-478f-a88a-cd81bc5636f7) | ![Chat List](https://github.com/user-attachments/assets/864bee44-eb9a-4223-bf45-859e36196861) |

| 03-2 Chat Room | 03-3 Share Movie | 03-4 Shared Movie List | 04-1 CINEMATE |
|----------------|------------------|------------------------|---------------|
| ![Chat Room](https://github.com/user-attachments/assets/7a53a866-5aad-4be6-ab18-e10e8fbcfeac) | ![Share Movie](https://github.com/user-attachments/assets/2b6484ef-062e-4859-9937-3e3224d8e20c) | ![Shared Movie List](https://github.com/user-attachments/assets/3e6a60b3-f111-4190-bcce-5f1e51b1d5ac) | ![CINEMATE](https://github.com/user-attachments/assets/6d1875b9-7522-4bf1-816e-110f1d83ce88) |

