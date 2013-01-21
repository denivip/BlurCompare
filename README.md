BlurCompare
===========
The BlurCompare project is an iOS app that contains two performance tests. It's purpose is to compare efficiency of various iOS frameworks in the context of blurring UI elements task. The basics of using frameworks for blurring images are described in the article "Blur effect in iOS applications" at our company's blog:
http://blog.denivip.ru/index.php/2013/01/blur-effect-in-ios-applications/?lang=en

##Frameworks##
BlurCompare compares performance of:
 - Core Image
 - Accelerate vImage
 - GPUImage

Core Image and vImage are Apple's frameworks for processing images. GPUImage is the free framework which purpose is to process images or live video from iPhone/iPad camera. GPUImage can be found on GitHub:
https://github.com/BradLarson/GPUImage

##Tests##
BlurCompare contains two tests: blurring moving area of static picture.
In the first test we compared framework's performance in blurring animated UI element. There is a screen divided into two parts. The first part is the original view that has picture and color square inside it. Picture is moving and changes its size. Color square is just moving. The second part is the view that represents contents of first view with blur effect.
The second test is showing the case of blurring moving fixed size area of static picture. This test shows us how the selective blur can be implemented. In the app you will see a big picture of Appollo starting off with a small rectangle area and below this area contents of original picture is blurred.
Both tests can be paused/continued with a single tap and display FPS at the top right corner of screen.

##Requirements##
This project requires iOS 6 in order to get Core Image blur filter working. However it will work at iOS 5 either but Core Image won't do anything in that case.

##TODO##
 - Add iPhone 5 support
 - Fix the issue with borders in the second test

##Known issues##
 - In the second test there is an issue when moving area intersects borders of underlying picture. Image in blurred moving area seem to stretch. Since the blurred area is cut from underlying and the processed with blur, when it goes through the border there is nothing to cut. And that causes image to stretch - size of area remains the same while it's content is less.
