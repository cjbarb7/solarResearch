function [  ] = gpuIsoonHyst( dirIsoon, dirMDI, intersectionSP, isoonHystTxtFile, isoonHystSegPath )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

ID = fopen(isoonHystTxtFile, 'wt');
fprintf(ID, 'hystersis segmentation\n');

isoonImageList = dir(dirIsoon);
mdiImageList = dir(dirMDI);

addPathOne = dirIsoon(1:(length(dirIsoon)-5));
addPathTwo = dirMDI(1:(length(dirMDI)-5));

addpath(addPathOne);
addpath(addPathTwo);

for i = 1:size(isoonImageList)-1
    
    imageNameOne = isoonImageList(i).name;
    imageNameTwo = isoonImageList((i+1)).name;
    
    stringOne = imageNameOne(8:19);
    stringTwo = imageNameTwo(8:19);
    imageISOONOne = imread(imageNameOne);
    imageISOONTwo = imread(imageNameTwo);
    
    imageISOONOne = imresize(imageISOONOne, [183 183], 'nearest');
    imageISOONTwo = imresize(imageISOONTwo, [183 183], 'nearest');
   % [m ,n] = size(imageISOONOne);
   % [m1 n1] = size(imageISOONTwo);
    
    %%convert to GPU
    
    if stringOne(1:10) == stringTwo(1:10)
        
        for j = 1:size(mdiImageList)
            mdiImageName = mdiImageList(j).name;
            mdiImageMat = load(mdiImageName);
            mdiImage = mat2gray(mdiImageMat.B);
            mdiImage = flipud(mdiImage);
            [mA mB] = size(mdiImage); 
            %mdiImage = imresize(mdiImage, 183/152, 'nearest');
            mdiStringCompare = strcat(mdiImageName(1:8), mdiImageName(10:13));
            if ((stringOne(1:9) == mdiStringCompare(1:9)) )
                fprintf(ID, 'string one is %, string two is %s, mdi string is %s\n', stringOne, stringTwo, mdiStringCompare);
                tic;
                
                
                
                im1GPU = gpuArray(imageISOONOne);
                im2GPU = gpuArray(imageISOONTwo);
                
                

                %im3GPU = gpuArray(mdiImage);

                %im3GPU = flipud(im3GPU);

               imageOnePlus = uint8(255*mat2gray(im1GPU));
               imageTwoPlus = uint8(255*mat2gray(im2GPU));

           
                imageOnePlus = double(imageOnePlus);
                imageTwoPlus = double(imageTwoPlus);

                find80imageOne = prctile(imageOnePlus, 100);

                findItOne = mean(mean(find80imageOne(:)));

                find80imageTwo = prctile(imageTwoPlus, 100);

                findItTwo = mean(mean(find80imageTwo(:)));


                findimageOne = prctile(imageOnePlus, 75);

                findOne = mean(mean(findimageOne(:)));

                findimageTwo = prctile(imageTwoPlus, 75);

                findTwo = mean(mean(findimageTwo(:)));

                h = fspecial('Gaussian',10,1.5); % 2.35482 due to relationship between FWHM and std
                H1 = imfilter(imageOnePlus,h,'replicate');
                H2 = imfilter(imageTwoPlus,h,'replicate');

                imageOnePlus = gather(imageOnePlus);
                imageTwoPlus = gather(imageTwoPlus);
                findOne = gather(findOne);
                findTwo = gather(findTwo);
                findItOne = gather(findItOne);
                findItTwo = gather(findItTwo);

                bw1 = hysthresh(imageOnePlus, findOne, findItOne);
                bw2 = hysthresh(imageTwoPlus, findTwo, findItTwo);

                B3 = bwareaopen(bw1,75);
                B4 = bwareaopen(bw2,75);

                B3 = gpuArray(B3);
                B4 = gpuArray(B4);

                se = strel('disk',1);
                D1 = imdilate(B3,se);
                D2 = imdilate(B4,se);


                D1b = bwdist(D1);
                D2b = bwdist(D2);

                D1b = gather(D1b);
                D1 = gather(D1);
                
                for i = 1:183
                    for j = 1:183

                        if D1b(i,j) < 10 
                            D1(i,j) = 1;
                        else
                            D1(i,j) = 0;
                        end
                    end
                end

                D2b = gather(D2b);
                D2 = gather(D2);
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

                DiffD = gather(Diff);

                B3_mod = D1 - and(abs(DiffD)>0,D1);


                % 
                % % Dilate mask
                B = imdilate(B3_mod,se);


                se1 = strel('disk',2);
                B5 = imdilate(B,se1);

                B5 = imresize(B5, [mA mB], 'nearest');
                
                 stringIsoon = strcat(imageNameOne(1:21),'_', imageNameTwo(1:21),'.jpg');
                stringPathIsoon = strcat(isoonHystSegPath,stringIsoon);
                imwrite(B5, stringPathIsoon, 'Bitdepth',12);
                
                B5Area = bwarea(B5);

                %mdiImage = gather(im3GPU);

               % mdiImage = imresize(mdiImage, 183/152, 'nearest');

                mdiArea = bwarea(mdiImage);

                intersection = mdiImage & B5;
                iArea = bwarea(intersection);

                percentage = iArea/mdiArea
               % percentageB = iArea/B5Area
                b =toc;
                fprintf(ID, 'Overlap percentage is %f\n', percentage);
                fprintf(ID, 'It took %f seconds \n', b);
                stringJPEG = strcat(imageNameOne(1:21), '_',imageNameTwo(1:21),'_MDI', mdiImageName(1:13), '.jpg');
                stringPathJPEG = strcat(intersectionSP,stringJPEG);
                
                imwrite(intersection, stringPathJPEG, 'Bitdepth',12);

                
                
                
                
                
                
                
                
                
                
                
            end
        end
    end
end

fclose(ID);

end