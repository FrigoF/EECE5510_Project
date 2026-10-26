%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: resize_image.m
% Author: Fred J. Frigo
% Description: Resample image if acquisition size differs from fftsize
%              zip_factor =1, means no interpolation
%              zip_factor =2, means factor of 2 interpolation, etc.
%
% @param raw_frams array containing the raw data to be displayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output_image = resize_image(input_image, da_xres, da_yres, zip_factor)
    
    num_rows = size(input_image,2);
    num_cols = size(input_image,1);
    yacq_size = (da_yres-1)*zip_factor;
    
    output_image = zeros( num_rows, num_cols);
    
    if (num_rows == (da_xres*zip_factor)) && (num_cols == ((da_yres-1)*zip_factor))
        output_image = input_image;
    elseif ( yacq_size ~= num_rows )
        temp_image = imresize( input_image, [num_rows, yacq_size]);
        row_offset = (num_cols - yacq_size) / 2;
        for j=1:num_rows
            for k=1:yacq_size
               output_image(j,k+row_offset)=temp_image(j,k);
            end
        end
    end    
    
end