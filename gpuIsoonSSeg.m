function [  ] = gpuIsoonSSeg( dirIsoon, dirMDI, intersectionSP, isoonSmartTxtFile, isoonSmartSegPath )

ID = fopen(isoonSmartTxtFile, 'wt');
fprintf(ID, 'smart segmentation\n');

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

                find80imageOne = prctile(imageOnePlus, 75);

                findItOne = median(median(find80imageOne(:)));

                find80imageTwo = prctile(imageTwoPlus, 75);

                findItTwo = median(median(find80imageTwo(:)));

                imageOnePlus = uint8(imageOnePlus);
                imageTwoPlus = uint8(imageTwoPlus);

                h = fspecial('Gaussian',10,1.1); % 2.35482 due to relationship between FWHM and std
                H1 = imfilter(imageOnePlus,h,'replicate');
                H2 = imfilter(imageTwoPlus,h,'replicate');


                % % Remove noise by zeroing pixels with absolute value less than 70G
                H1(abs(H1)<50) = 0;
                H2(abs(H2)<50) = 0;

                % % Create binary masks
                B1 = abs(H1)>=findItOne;
                B2 = abs(H2)>=findItTwo;

                B1 = gather(B1);
                B2 = gather(B2);
                %%after gpu stuff

                B3 = bwareaopen(B1,75);
                B4 = bwareaopen(B2,75);


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

                B = imdilate(B, se1);
                
                stringIsoon = strcat(imageNameOne(1:21),'_', imageNameTwo(1:21),'.jpg');
                stringPathIsoon = strcat(isoonSmartSegPath,stringIsoon);
                 B = imresize(B, [mA mB],'nearest');
                imwrite(B, stringPathIsoon, 'Bitdepth',12);
            
                
                Barea = bwarea(B);

               

                mdiArea = bwarea(mdiImage);

               
                intersection = mdiImage & B;
                iArea = bwarea(intersection);

                percentage = iArea/mdiArea
                
                b = toc;
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

