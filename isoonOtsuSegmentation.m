function [  ] = isoonOtsuSegmentation( directoryOfIsoon, directoryOfMDI, intersectionStringPath, isoonTxtFile, isoonSegmentationImagePath )
%This function performs segmentation on two isoon images to detect for
%active regions within a small time lapse.  Then that segmentation that is
%preprocessed to remove erroneous materials is checked with the mdi image
%segmentation of smart implementation to see how much overlap between
%h-alpha and mdi, but before segmentation it segments using otsu's
%threshold
%
%input: 
%
%   directoryOfIsoon - directory of where the images are at, should end
%   with *.jpg to get the images
%   directoryofMDI - same like directoryOfIsoon except end with *mat and
%   have ' ' for both
%   intersectionStringPath - this is the string ' ' to place where you want
%   the image segmentation overlap of mdi and isoon
%   isoonTxtFile - this is the text file that describes overlap percentage,
%   isoon and mdi images used per iteration, and this is a path to place it
%   so a string ' '


%%ID = fopen('/Users/cjbarberan/Desktop/smartSegment/ARDATA/0213/AR2013.txt', 'wt');
ID = fopen(isoonTxtFile, 'wt');
fprintf(ID, 'otsu\n');

%imageList = dir('/Users/cjbarberan/Desktop/smartSegment/ARDATA/0213/*.jpg');
%mdiImageList = dir('/Users/cjbarberan/Desktop/smartSegment/mdiSmart/0213/SMART_seg/*.mat');

imageList = dir(directoryOfIsoon);
mdiImageList = dir(directoryOfMDI);

addPathOne = directoryOfIsoon(1:(length(directoryOfIsoon)-5));
addPathTwo = directoryOfMDI(1:(length(directoryOfMDI)-5));

addpath(addPathOne);
addpath(addPathTwo);


%cellArray = cell(size(imageList));
%cellArray.hasValue = zeros(size(mdiImageList),size(imageList));



for i = 1:size(imageList)-1;
    
    
    
    imageNameOne = imageList(i).name;
    imageNameTwo = imageList((i+1)).name;
    [m n] = size(imageNameOne);
    stringOne = imageNameOne(8:19);
    stringTwo = imageNameTwo(8:19);
    %imageMat = load(imageName);
    %image = mat2gray(imageMat.B);
    imageISOONOne = imread(imageNameOne);
    imageISOONTwo = imread(imageNameTwo);
    
    imageISOONOne = imresize(imageISOONOne, [183 183], 'nearest');
    imageISOONTwo = imresize(imageISOONTwo, [183 183], 'nearest');
    
    if stringOne(1:10) == stringTwo(1:10)
        
       for j = 1:size(mdiImageList)
           mdiImageName = mdiImageList(j).name;
           mdiImageMat = load(mdiImageName);
           mdiImage = mat2gray(mdiImageMat.B);
           mdiImage = flipud(mdiImage);
           [mA mB] = size(mdiImage);
           
           mdiStringCompare = strcat(mdiImageName(1:8),mdiImageName(10:13));
           if stringOne(1:9) == mdiStringCompare(1:9)
               fprintf(ID, 'String one is %s, string two is %s, mdi String is %s\n', stringOne, stringTwo, mdiStringCompare);
               
               %%smart segment
               imageOnePlus = uint8(255*mat2gray(imageISOONOne));
               imageTwoPlus = uint8(255*mat2gray(imageISOONTwo));
               
               %%percentile to acquire active regions
               %find80imageOne = prctile(imageOnePlus, 75);

                %findItOne = mean(mean(find80imageOne(:)));

            %find80imageTwo = prctile(imageTwoPlus, 75);

            %findItTwo = mean(mean(find80imageTwo(:)));

%%otsu thresholding
[levelOne EM1] = graythresh(imageOnePlus);
[levelTwo EM2] = graythresh(imageTwoPlus);

%%thresholding to acquire active regions
BW1 = im2bw(imageOnePlus, levelOne);
BW2 = im2bw(imageTwoPlus, levelTwo);

%removing small araes
B3 = bwareaopen(BW1,75);
B4 = bwareaopen(BW2,75);


% 
% % Dilate masks
se = strel('disk',1);
D1 = imdilate(B3,se);
D2 = imdilate(B4,se);


D1b = bwdist(D1);
D2b = bwdist(D2);

for i = 1:183
    for j = 1:183
        
        if D1b(i,j) < 10 
            D1(i,j) = 1;
        else
            D1(i,j) = 0;
        end
    end
end

for i = 1:183
    for j = 1:183
        
        if D2b(i,j) < 10 
            D2(i,j) = 1;
        else
            D2(i,j) = 0;
        end
    end
end


% 
% % Compute difference in masks
Diff = D2 - D1;

% 
% % Remove transient regions from un-dilated mask
B3_mod = D1 - and(abs(Diff)>0,D1);
% 
% % Dilate mask
B = imdilate(B3_mod,se);


se1 = strel('disk',2);
Blarge = imdilate(B,se1);

                stringIsoon = strcat(imageNameOne(1:21),'_',imageNameTwo(1:21),'otsu.jpg');
                stringPathIsoon = strcat(isoonSegmentationImagePath, stringIsoon);
                
                Blarge = imresize(Blarge, [mA mB], 'nearest');

                
                imwrite(Blarge,stringPathIsoon, 'Bitdepth',12); 

%mdiImage = imresize(mdiImage, 183/152, 'nearest');

mdiArea = bwarea(mdiImage);

intersection = mdiImage & Blarge;
iArea = bwarea(intersection);

percentage = iArea/mdiArea
                fprintf(ID, 'Overlap percentage is %f\n', percentage);
                
               %% stringPath = '/Users/cjbarberan/Desktop/smartSegment/ARDATA/0213/segmentationImages/';
                stringJPEG = strcat(imageNameOne(1:21),'_',imageNameTwo(1:21),'_MDI',mdiImageName(1:13),'.jpg');
                stringPathJPG = strcat(intersectionStringPath,stringJPEG);
                
                imwrite(intersection,stringPathJPG,'Bitdepth',12);
                
                
                
                
                
               
               
               
           end
       end
        
        
    end
    
    
           
end



fclose(ID);


end

