%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: resize_image.m
% Author: Fred J. Frigo
% Description: Resample image if acquisition size differs from fftsize
%              zip_factor =1, means no interpolation
%              zip_factor =2, means factor of 2 interpolation, etc.
%
% @param raw_frams array containing the raw data to be displayed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output_image = resize_image(input_image, pfile, zip_factor)

    fid = fopen(pfile,'r', 'ieee-le');
    status = fseek(fid, 0, 'bof');
    [f_hdr_value, count] = fread(fid, 1, 'real*4');
    rdbm_rev_num = f_hdr_value(1);

    % Read header information
    if (rdbm_rev_num < 26.0 )
        status = fseek(fid, 0, 'bof');
    else
        status = fseek(fid, 76, 'bof'); % skip 76 bytes of data added for 26.0
    end
    [hdr_value, count] = fread(fid, 102, 'integer*2');
    
    da_xres = hdr_value(52);
    da_yres = hdr_value(53);
    rc_xres = hdr_value(54);
    rc_yres = hdr_value(55);
    
    num_rows = size(input_image,2);
    num_cols = size(input_image,1);
    yacq_size = (da_yres-1)*zip_factor;
    
    output_image = zeros( num_rows, num_cols);
    
    if (num_rows == da_xres) && (num_cols == (da_yres-1))
        output_image = input_image;
    elseif ( yacq_size ~= num_rows )
        temp_image = imresize( input_image, [num_rows, yacq_size]);
        row_offset = (num_cols - yacq_size) / 2;
        for j=1:num_rows
            for k=1:yacq_size
               output_image(j,k+row_offset)=temp_image(j,k);
            end
        end
        output_image = uint16(output_image); % 16 bit integer
    end  
    
    % Display image
    figure 
    imagesc(output_image);
    colormap('gray');
    title('Sum of Squares Image');
end