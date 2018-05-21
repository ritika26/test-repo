import cv2
import numpy as np
import sys

image = cv2.cvtColor(cv2.imread('/Users/ritikaagarwal/Documents/OfficeProject/images/SampleImage.jpeg'), cv2.COLOR_BGR2RGB)

def resize(img, height=800):
    """ Resize image to given height """
    rat = height / img.shape[0]
    return cv2.resize(img, (int(rat * img.shape[1]), height))

# Resize and convert to grayscale
gray_scale = cv2.cvtColor(resize(image), cv2.COLOR_BGR2GRAY)
cv2.imshow("GrayScaledImage",gray_scale)
cv2.imwrite("GrayScaledImage.jpg",gray_scale)
copied_img=gray_scale.copy()

# Bilateral filter preserv edges
billateral_img = cv2.bilateralFilter(gray_scale, 9, 75, 75)
cv2.imshow("BilateralFiltering",billateral_img)
cv2.imwrite("Bilateral.jpg",billateral_img)

# Create black and white image based on adaptive threshold
bwimg = cv2.adaptiveThreshold(billateral_img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 115, 4)
cv2.imshow("ThresholdedImage",bwimg)
cv2.imwrite("thresholded.jpg",bwimg)
#######################

kernel=np.ones((3,3))
smoothed= cv2.dilate(bwimg,kernel,iterations=3)
cv2.imwrite("Smoothedimage.jpg",smoothed)
smoothed_1= cv2.erode(smoothed,None,iterations=3)
processed= cv2.medianBlur(smoothed_1,11)
cv2.imshow("Processedimage",processed)
cv2.imwrite("ProcessedImage.jpg",processed)
#################


# Median filter clears small details
med_filt = cv2.GaussianBlur(bwimg, (3,3),0)
cv2.imshow("BlurredImage",med_filt)
cv2.imwrite("blurred.jpg",med_filt)


# Add black border in case that page is touching an image border
bb= cv2.copyMakeBorder(med_filt, 5, 5, 5, 5, cv2.BORDER_CONSTANT, value=[0, 0, 0])
cv2.imshow("AddingBlackborder",bb)
cv2.imwrite("Blackborder.jpg",bb)

def auto_canny(image, sigma=0.33):
        v= np.median(image)
        lower = int(max(0, (1.0 - sigma) * v))
        upper = int(min(255, (1.0 + sigma) * v))
        edged = cv2.Canny(image, lower, upper)
        return edged
edges = auto_canny(bb)

#edges = cv2.Canny(gray_scale, 200, 250)
cv2.imshow("Edges",edges)
cv2.imwrite("Edged.jpg",edges)


# Getting contours  
#im2, contours, hierarchy = cv2.findContours(edges.copy(), cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
#(_, cnts, _) = cv2.findContours(edges.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

im2, contours, hierarchy = cv2.findContours(edges, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
cv2.drawContours(copied_img, contours, -1, (0, 255, 0), 2)
print("Found {} EXTERNAL contours".format(len(contours)))
print(contours)
obj_corn=[]

for (i, c) in enumerate(contours):
        #rect = cv2.minAreaRect(c)
        area = cv2.contourArea(c)
        (x, y, w, h) = cv2.boundingRect(c)
        #cv2.rectangle(resized, (x-5, y-5), (x + w+5, y + h+5), (0, 255, 0), 2)
        ROI=copied_img[y - 5:y + h + 5, x - 5:x + w + 5]
        cv2.imshow('ROI',ROI)
        pp=cv2.rectangle(copied_img, (x-5, y-5), (x + w+5, y + h+5), (0, 255, 0), 2)
        cv2.imwrite("result1.png", pp)
        out_count='obj_%s_%s_%s_%s.png'%(x,y,w,h)
        cv2.imwrite(out_count,ROI)
        obj_corn.append([x,y,w,h])
cv2.waitKey(0)  
    

# Finding contour of biggest rectangle
# Otherwise return corners of original image
# Don't forget on our 5px border!


