function [  ] = isoonSmartSegmentation( directoryOfIsoon, directoryOfMDI, intersectionStringPath, isoonTxtFile,isoonSegmentationImagePath )
%This function performs segmentation on two isoon images to detect for
%active regions within a small time lapse.  Then that segmentation that is
%preprocessed to remove erroneous materials is checked with the mdi image
%segmentation of smart implementation to see how much overlap between
%h-alpha and mdi
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
%
%

%%ID = fopen('/Users/cjbarberan/Desktop/smartSegment/ARDATA/0213/AR2013.txt', 'wt');
ID = fopen(isoonTxtFile, 'wt');
fprintf(ID, 'smart segmentation\n');

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



for i = 1:size(imageList)-1
    
    
    
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
               
               find80imageOne = prctile(imageOnePlus, 75);

                findItOne = median(median(find80imageOne(:)));

                find80imageTwo = prctile(imageTwoPlus, 75);

                findItTwo = median(median(find80imageTwo(:)));
               
               h = fspecial('Gaussian',10,1.1); % 2.35482 due to relationship between FWHM and std
                H1 = imfilter(imageOnePlus,h,'replicate');
                H2 = imfilter(imageTwoPlus,h,'replicate');

                H1(abs(H1)<50) = 0;
                H2(abs(H2)<50) = 0;

               
                B1 = abs(H1)>=findItOne;
                B2 = abs(H2)>=findItTwo;
               
               
                B3 = bwareaopen(B1,75);
                B4 = bwareaopen(B2,75);
               
               
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
                
                Diff = D2 - D1;
                
                B3_mod = D1 - and(abs(Diff)>0,D1);
                
                B = imdilate(B3_mod,se);

                se1 = strel('disk',2);

                B = imdilate(B, se1);
                
                %%write isoon segmentation images to the isoon path
                stringIsoon = strcat(imageNameOne(1:21),'_',imageNameTwo(1:21),'.jpg');
                stringPathIsoon = strcat(isoonSegmentationImagePath, stringIsoon);
                
                B = imresize(B, [mA mB], 'nearest');
                
                imwrite(B,stringPathIsoon, 'Bitdepth',12); 

                Barea = bwarea(B);
                
                
               % mdiImage = imresize(mdiImage, 183/152, 'nearest');

                mdiArea = bwarea(mdiImage);
                
                intersection = mdiImage & B;
                iArea = bwarea(intersection);

                percentage = iArea/mdiArea;
                fprintf(ID, 'Overlap percentage is %f\n', percentage);
                
               %% stringPath = '/Users/cjbarberan/Desktop/smartSegment/ARDATA/0213/segmentationImages/';
                stringJPEG = strcat(imageNameOne(1:21),'_',imageNameTwo(1:21),'_MDI',mdiImageName(1:13),'.jpg');
                stringPathJPG = strcat(intersectionStringPath,stringJPEG);
                
                imwrite(intersection,stringPathJPG,'Bitdepth',12);
                
                
                
                
                
               
               
               
           end
       end
        
        
    end
    
    
    
    %figure()
    %imagesc(mdiImage)
    %colormap('gray');
    
   
    %mdiStringCompare = strcat(mdiImageName(1:8),mdiImageName(10:13))
    
    
%     for j = 1:size(mdiImageList)
%         isoonImageName = imageList(j).name;
%         value = strncmp(mdiStringCompare, isoonImageName(8:21), 10)
%         if value ~= 0
%            
%             cellArray.hasValue(j,i) = 1
%             
%         end
%         
%         
%     end
        
end



fclose(ID);

end

