dataset_dir = 'C:\dev\datasets\NewPipelineResults0\images';
    
%Load src images
fprintf(1, 'Loading images.\n');
src_files = [ dir(fullfile(dataset_dir, '*.tif')); ...
    dir(fullfile(dataset_dir, '*.png')) ];
src_files = sort({src_files.name});
    
src_info = imfinfo(fullfile(src_folder, src_files{1}));
% Assume all images are the same size
    
    for zi = 1:length(src_files)
        img = imread(fullfile(src_folder, src_files{zi}));
        if(size(img, 3)) == 3
            %Ignore color
            src_vol(:,:,zi) = uint32(img(:,:,1));
        else
            src_vol(:,:,zi) = img;
        end
        src_vol(:,:,zi) = imadjust(src_vol(:,:,zi));
    end
    
    %Load probabilities
    fprintf(1, 'Loading probabilities.\n');
    prob_folder = fullfile(src_dir, 'forest_prob_adj');
    prob_files = [ dir(fullfile(prob_folder, '*.mat')) ];
    prob_files = sort({prob_files.name});
    
    for zi = 1:length(prob_files)
        load_img = load(fullfile(prob_folder, prob_files{zi}), 'imProb');
        prob_vol(:,:,zi) = load_img.imProb;
    end
    clear load_img;
    
    
    %Load segmentation
    fprintf(1, 'Loading segmentation.\n');
    seg_folder = fullfile(src_dir, dice_string, result_name, ['FS=' num2str(nresult)], 'stitched', 'labels');
    seg_files = [ dir(fullfile(seg_folder, '*.tif')); ...
        dir(fullfile(seg_folder, '*.png')) ];
    seg_files = sort({seg_files.name});
    
    % Load seg data
    for zi = 1:length(seg_files)
        img = imread(fullfile(seg_folder, seg_files{zi}));
        if(size(img, 3)) == 3
            %Map 8-bit color image to 32 bit
            seg_vol(:,:,zi) = uint32(img(:,:,1));
            seg_vol(:,:,zi) = seg_vol(:,:,zi) + uint32(img(:,:,2)) * 2^8;
            seg_vol(:,:,zi) = seg_vol(:,:,zi) + uint32(img(:,:,3)) * 2^16;
        else
            seg_vol(:,:,zi) = img;
        end
    end
    
    %Compress labels
    [~, ~, seg_index] = unique(seg_vol(:));
    seg_vol = reshape(uint32(seg_index)-1, size(seg_vol));
    
    %Grow regions until there are no more black lines
    borders = seg_vol==0;
    dnum = 0;
    disk1 = strel('disk', 1, 4);
    while any(borders(:))
        dvol = imdilate(seg_vol, disk1);
        seg_vol(borders) = dvol(borders);
        borders = seg_vol==0;
        
        dnum = dnum + 1;
        fprintf(1, 'Growing regions: %d.\n', dnum);
    end
%end

sz = size(seg_vol);
segs = double(max(seg_vol(:)));

segments = seg_vol;

for minsegsize = [0];
    
    %close all;
    %quickshowdualhsv_demo(src_vol, segments)
    
    disp('Cleaning...');
    cleanseg = clean1(segments);
    %close all;
    %quickshowdualhsv_demo(src_vol, cleanseg)
    
    save(sprintf('PostJoin_%s_%s_FS%d_Size=%d.mat', subvol_name, result_name, nresult, minsegsize), 'segments', 'cleanseg');
    
    %prepare for more joining
    seg_vol = segments;
    
end