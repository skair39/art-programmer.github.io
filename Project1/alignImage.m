function [ displacement_G, displacement_R ] = alignImage( image_filename, initial_search_range_delta, num_pyramid_levels )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

ori_image = imread(image_filename);

%%
% crop the image
if false
    gray_scale_threshold = 200;
    x_min_colors = min(ori_image);
    min_x = find(x_min_colors < gray_scale_threshold, 1, 'first');
    max_x = find(x_min_colors < gray_scale_threshold, 1, 'last');
    y_min_colors = min(ori_image, [], 2);
    min_y = find(y_min_colors < gray_scale_threshold, 1, 'first');
    max_y = find(y_min_colors < gray_scale_threshold, 1, 'last');
    ori_image = ori_image(min_y:max_y, min_x:max_x);
    %imwrite(ori_image, 'cropped_image.bmp');
end
%%

[height, width] = size(ori_image);
height = uint16(floor(height / 3));

B_image_ori = ori_image(1:height, :);
G_image_ori = ori_image((height + 1) : (height * 2), :);
R_image_ori = ori_image((height * 2 + 1) : height * 3, :);

imwrite(B_image_ori, 'image_B.bmp');
imwrite(G_image_ori, 'image_G.bmp');
imwrite(R_image_ori, 'image_R.bmp');
% return;

% B_image_ori = zeros(100, 100);
% B_image_ori(50, :) = 1.0;
% G_image_ori = zeros(100, 100);
% G_image_ori(25, :) = 1.0;
% R_image_ori = zeros(100, 100);
% R_image_ori(75, :) = 1.0;
% [height, width] = size(B_image_ori);

filter_size = 3;

B_image_pyramid{1} = B_image_ori;
G_image_pyramid{1} = G_image_ori;
R_image_pyramid{1} = R_image_ori;
for level = 2:num_pyramid_levels
    F = fspecial('gaussian', filter_size, filter_size / 3);
    filtered_B_image = imfilter(B_image_pyramid{level - 1}, F);
    B_image_pyramid{level} = filtered_B_image(1:2:end, 1:2:end);
%    B_image_pyramid{level} = imresize(filtered_B_image, 0.5);
    filtered_G_image = imfilter(G_image_pyramid{level - 1}, F);
    G_image_pyramid{level} = filtered_G_image(1:2:end, 1:2:end);
%    G_image_pyramid{level} = imresize(filtered_G_image, 0.5);
    filtered_R_image = imfilter(R_image_pyramid{level - 1}, F);
    R_image_pyramid{level} = filtered_R_image(1:2:end, 1:2:end);
%    R_image_pyramid{level} = imresize(filtered_R_image, 0.5);
    %filter_size = filter_size * 2;
end

% B_image_ori = B_image_pyramid{num_pyramid_levels};
% G_image_ori = G_image_pyramid{num_pyramid_levels};
% R_image_ori = R_image_pyramid{num_pyramid_levels};
% [height, width] = size(B_image_ori);
% B_image_pyramid{1} = B_image_ori;
% G_image_pyramid{1} = G_image_ori;
% R_image_pyramid{1} = R_image_ori;
% num_pyramid_levels = 1;


upper_level_displacement_G = [0, 0];
upper_level_displacement_R = [0, 0];
search_range_delta = initial_search_range_delta;
accumulative_search_range_delta = 2;

for level = num_pyramid_levels: -1 : 1
    %border_width = uint8(0);
    border_width = uint16(max(width, height) / 2^(level - 1) * 0.1);
    min_distance_G = inf;
    min_distance_displacement_G = upper_level_displacement_G * 2;
    for displacement_x = upper_level_displacement_G(1) * 2 - search_range_delta:upper_level_displacement_G(1) * 2 + search_range_delta
        for displacement_y = upper_level_displacement_G(2) * 2 - search_range_delta:upper_level_displacement_G(2) * 2 + search_range_delta
            B_image_region = double(B_image_pyramid{level}(1 + max(displacement_y, 0):end + min(displacement_y, 0), 1 + max(displacement_x, 0):end + min(displacement_x, 0)));
            G_image_region = double(G_image_pyramid{level}(1 + max(-displacement_y, 0):end + min(-displacement_y, 0), 1 + max(-displacement_x, 0):end + min(-displacement_x, 0)));
            B_image_region = B_image_region(1 + border_width:end-border_width, 1 + border_width:end-border_width);
            G_image_region = G_image_region(1 + border_width:end-border_width, 1 + border_width:end-border_width);
            if false
                [B_image_region_gradient_x, B_image_region_gradient_y] = imgradientxy(B_image_region);
                B_image_region = [B_image_region_gradient_x; B_image_region_gradient_y];
                [G_image_region_gradient_x, G_image_region_gradient_y] = imgradientxy(G_image_region);
                G_image_region = [G_image_region_gradient_x; G_image_region_gradient_y];
            end
            if false
                Laplacian_filter = fspecial('laplacian');
                B_image_region = imfilter(B_image_region, Laplacian_filter);
                G_image_region = imfilter(G_image_region, Laplacian_filter);
                %B_image_region = double(edge(B_image_region));
                %G_image_region = double(edge(G_image_region));
            end
%            distance_G = sum(abs(B_image_region(:) - G_image_region(:)));
            distance_G = 1 - sum(B_image_region(:) .* G_image_region(:)) / (norm(B_image_region(:)) * norm(G_image_region(:)));
            if (distance_G < min_distance_G)
                min_distance_displacement_G = [displacement_x, displacement_y];
                min_distance_G = distance_G;
                
                [displacement_x, displacement_y, distance_G];
            end
        end
    end
    upper_level_displacement_G = min_distance_displacement_G;
    
    min_distance_R = inf;
    min_distance_displacement_R = upper_level_displacement_R * 2;
    for displacement_x = upper_level_displacement_R(1) * 2 - search_range_delta:upper_level_displacement_R(1) * 2 + search_range_delta
        for displacement_y = upper_level_displacement_R(2) * 2 - search_range_delta:upper_level_displacement_R(2) * 2 + search_range_delta
            B_image_region = double(B_image_pyramid{level}(1 + max(displacement_y, 0):end + min(displacement_y, 0), 1 + max(displacement_x, 0):end + min(displacement_x, 0)));
            R_image_region = double(R_image_pyramid{level}(1 + max(-displacement_y, 0):end + min(-displacement_y, 0), 1 + max(-displacement_x, 0):end + min(-displacement_x, 0)));
            B_image_region = B_image_region(1 + border_width:end-border_width, 1 + border_width:end-border_width);
            R_image_region = R_image_region(1 + border_width:end-border_width, 1 + border_width:end-border_width);
            if false
                [B_image_region_gradient_x, B_image_region_gradient_y] = imgradientxy(B_image_region);
                B_image_region = [B_image_region_gradient_x; B_image_region_gradient_y];
                [R_image_region_gradient_x, R_image_region_gradient_y] = imgradientxy(R_image_region);
                R_image_region = [R_image_region_gradient_x; R_image_region_gradient_y];
            end
            if false
                Laplacian_filter = fspecial('laplacian');
                B_image_region = imfilter(B_image_region, Laplacian_filter);
                R_image_region = imfilter(R_image_region, Laplacian_filter);
                %B_image_region = double(edge(B_image_region));
                %R_image_region = double(edge(R_image_region));
            end
            %            distance_R = sum(abs(B_image_region(:) - R_image_region(:)));
            distance_R = 1 - sum(B_image_region(:) .* R_image_region(:)) / (norm(B_image_region(:)) * norm(R_image_region(:)));
            if (distance_R < min_distance_R)
                min_distance_displacement_R = [displacement_x, displacement_y];
                min_distance_R = distance_R;
                
                [displacement_x, displacement_y, distance_R];
            end
        end
    end
    upper_level_displacement_R = min_distance_displacement_R;
    
    search_range_delta = accumulative_search_range_delta;
end

displacement_G = upper_level_displacement_G;
displacement_R = upper_level_displacement_R;

common_x_range = [1 + max(0, max(displacement_G(1), displacement_R(1))), width + min(0, min(displacement_G(1), displacement_R(1)))];
common_y_range = [1 + max(0, max(displacement_G(2), displacement_R(2))), height + min(0, min(displacement_G(2), displacement_R(2)))];
B_image_region = B_image_ori(common_y_range(1):common_y_range(2), common_x_range(1):common_x_range(2));
G_image_region = G_image_ori(max(common_y_range(1) - displacement_G(2), 1):min(common_y_range(2) - displacement_G(2), height), max(common_x_range(1) - displacement_G(1), 1):min(common_x_range(2) - displacement_G(1), width));
R_image_region = R_image_ori(max(common_y_range(1) - displacement_R(2), 1):min(common_y_range(2) - displacement_R(2), height), max(common_x_range(1) - displacement_R(1), 1):min(common_x_range(2) - displacement_R(1), width));

if false
    B_image_region = histeq(B_image_region);
    G_image_region = histeq(G_image_region);
    R_image_region = histeq(R_image_region);
end

composited_image = cat(3, R_image_region, G_image_region, B_image_region);
composited_image_better_color_mapping = cat(3, uint8(double(R_image_region) * 0.9), uint8(double(G_image_region) * 0.9), uint8(double(B_image_region) * 1.0));
figure();
subplot(1, 2, 1); subimage(composited_image_better_color_mapping);
title('with better color mapping');
%subplot(1, 2, 2); imshow(R_image_ori);
%subplot(1, 2, 2); subimage(cat(3, R_image_ori, G_image_ori, B_image_ori));
ori_composited_image = imread('composited_image.bmp');
subplot(1, 2, 2); subimage(ori_composited_image);
title('with original color mapping');
imwrite(composited_image, 'composited_image.bmp');
imwrite(cat(3, R_image_ori, G_image_ori, B_image_ori), 'composited_image_ori.bmp');
end

