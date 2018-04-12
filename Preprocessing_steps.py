# import the necessary package
import cv2
import os, os.path
import imutils
import matplotlib.pyplot as plt
import numpy as np
import argparse
from sklearn.externals import joblib

#image path and valid extensions
def sort_contours(cnts, method="left-to-right"):
    	# initialize the reverse flag and sort index
	reverse = False
	i = 0
	# handle if we need to sort in reverse
	if method == "right-to-left" or method == "bottom-to-top":
		reverse = True

	# handle if we are sorting against the y-coordinate rather than
	# the x-coordinate of the bounding box
	if method == "top-to-bottom" or method == "bottom-to-top":
		i = 1

	# construct the list of bounding boxes and sort them from top to
	# bottom
	boundingBoxes = [cv2.boundingRect(c) for c in cnts]
	(cnts, boundingBoxes) = zip(*sorted(zip(cnts, boundingBoxes),
		key=lambda b:b[1][i], reverse=reverse))

	# return the list of sorted contours and bounding boxes
	return (cnts, boundingBoxes)


imageDir = "/Users/ritikaagarwal/Documents/ImageProcessing_Project/images1"
image_path_list = []
valid_image_extensions = [".jpg", ".jpeg", ".png", ".tif", ".tiff"] #specify your vald extensions here
valid_image_extensions = [item.lower() for item in valid_image_extensions]
 
#create a list all files in directory and append files with a vaild extention to image_path_list
for file in os.listdir(imageDir):
    extension = os.path.splitext(file)[1]
    if extension.lower() not in valid_image_extensions:
        continue
    image_path_list.append(os.path.join(imageDir, file))
 
#loop through image_path_list to open each image
for imagePath in image_path_list:
    image = cv2.imread(imagePath)
    # load the image, convert it to grayscale, and blur it
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # Resizing an image by calling imutils function
    resized = imutils.resize(gray, height =600)
    cv2.imshow("Resized via Function", resized)
    blurred = cv2.GaussianBlur(resized, (3, 3), 0)
    cv2.imshow("GaussianImage", blurred)
    cv2.imwrite("blurred.jpg",blurred)
    thresh = cv2.adaptiveThreshold(blurred, 255,cv2.ADAPTIVE_THRESH_MEAN_C, cv2.THRESH_BINARY_INV, 11,4 )
    cv2.imshow("Mean Thresh", thresh)
    cv2.imwrite("Thresholded_image.jpg",thresh)
    Kernel = np.ones((5,5),np.uint8)
    smoothed = cv2.dilate(thresh,Kernel,iterations = 3)
    #smoothed = cv2.GaussianBlur(thresh,(3,3),0)
    #smoothed = cv2.dilate(thresh,None,iterations = 3)
    smoothed_1 = cv2.erode(smoothed,None,iterations = 3)
    cv2.imshow("ErodedImage", smoothed_1)
    cv2.imwrite("Eroded_Image.jpg",smoothed_1)
    processed = cv2.medianBlur(smoothed_1,11)
    def auto_canny(image, sigma=0.33):
        v= np.median(image)
        lower = int(max(0, (1.0 - sigma) * v))
        upper = int(min(255, (1.0 + sigma) * v))
        edged = cv2.Canny(image, lower, upper)
        return edged
    auto = auto_canny(processed)
    cv2.imshow("Edges", auto)
    cv2.imwrite("EdgedImage.jpg",auto)
    forms = resized.copy()
    (_, cnts, _) = cv2.findContours(auto.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    cv2.drawContours(forms, cnts, -1, (0, 255, 0), 2)
    print("Found {} EXTERNAL contours".format(len(cnts)))
    print(cnts)
    obj_corn=[]
    cnt_image = sort_contours(cnts,"left-to-right")

    for (i, c) in enumerate(cnts):
        #rect = cv2.minAreaRect(c)
        area = cv2.contourArea(c)
        (x, y, w, h) = cv2.boundingRect(c)
        cv2.rectangle(resized, (x-5, y-5), (x + w+5, y + h+5), (0, 255, 0), 2)
        ROI=resized[y - 5:y + h + 5, x - 5:x + w + 5]
        cv2.imshow('ROI',ROI)
        pp=cv2.rectangle(resized, (x-5, y-5), (x + w+5, y + h+5), (0, 255, 0), 2)
        cv2.imwrite("result1.png", pp)
        out_count='obj_%s_%s_%s_%s.png'%(x,y,w,h)
        cv2.imwrite(out_count,ROI)
        obj_corn.append([x,y,w,h])
        cv2.waitKey(0)

    