function img  = SlidingWindow(imagePath, classifier)

    %% Setup
    addpath .\SVM-KM\
    addpath .\Classifiers\
    addpath .\Data\

    %Open testing image and convert to gray scale
    I=imread(imagePath);

    I=double(I);
    %I = rgb2gray(I);

    %samplingX=round(size(I,1)/numberRows);
    windowWidth = round(96 * .8);
    windowHeight = round(160 * .8);
    %samplingY=round(size(I,2)/numberColumns);


    pedCounter=0;

    %Implementation of a simplified slidding window
    % we will be accumulating all the predictions in this variable
    predictedFullImage=[];
    BBs = [];

    %% Setup masks for edge extraction

    maskA = [1 , 0; 0 , -1];
    maskB = [0, 1 ; -1, 0];
    
    %maskA = ones(3);
    %maskA(:,1) = maskA(:,1) - 2;
    %maskA(:,2) = maskA(:,2) - 1;

    %maskB = ones(3);
    %maskB(:,1) = maskB(:,1) - 2;
    %maskB(:,2) = maskB(:,2) - 1;

    %% Create image pyramid
    p1 = impyramid(I,'reduce');
    p2 = impyramid(p1, 'reduce');
    p3 = impyramid(p2,'reduce');

    %% Iteration
    for pyramid = 1:4

        pyramidImage = [];
        % terrible code but  matlab doesn't allow array of arrays without 4d
        % matrix - and thats far too confusing
        if(pyramid == 1)
            pyramidImage = I;
        elseif(pyramid == 2)
            pyramidImage = p1;
        elseif(pyramid ==3)
            pyramidImage = p2;
        elseif(pyramid ==4)
            pyramidImage = p3;
        end


        for r=1:windowHeight/2:size(pyramidImage,1)
            predictedRow=[];

            for c= 1:windowWidth/2:size(pyramidImage,2)

                if (c+windowWidth-1 <= size(pyramidImage,2)) && (r+windowHeight-1 <= size(pyramidImage,1))

                    %we crop the full image to the sliding window size
                    image = pyramidImage(r:r+windowHeight-1, c:c+windowWidth-1);

                    %% imageHE = histeq(uint8(image), 255);

                    % Resize to 160*96 because the training set images were this
                    % size
                    image = imresize(image,[160 96]);

              
                    %extract edges
                    [ImEdEx, ImIhor, ImIver] =  edgeExtraction(image,maskA, maskB);

                    % Get hog
                    hogEdEx = hog_feature_vector(ImEdEx);

                   
                    prediction =  classifier.test(hogEdEx);

                    
                    if prediction == 1
                        pedCounter = pedCounter+1;
                        
                        
                        BB = [r * (2 .^ (pyramid -1)) c * (2 .^ (pyramid - 1)) windowHeight * (2 .^ (pyramid -1)) windowWidth * (2 .^ (pyramid -1))];
                        BBs = [BBs; BB];
                    end

                    %predictedRow=[predictedRow prediction];
                end
            end


        end
    end

    figure

    imshow(uint8(I)), hold on



    for k=1:size(BBs)
        rectangle('Position', [BBs(k,2) BBs(k,1) BBs(k,4), BBs(k,3)])
    end

    save_path = replace(imagePath, 'pedestrian','videoFrames_final');
    export_fig(save_path);

end


