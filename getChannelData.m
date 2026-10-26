%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: getChannelData.m
% Author: Jason Darby
% Description: Retrieves the raw data frames from a given pfile for 
%               a given slice and channel.
% Note: This file is a modified version of raw_image.m by Fred Frigo
%
% 
% Fred Frigo   - updated Oct 15, 2020 to support 25.0 and 26.0
% Fred Frigo   - updated Feb 22, 2025 gradwarp updates
%
% @param pfile the path to the raw-data file to be read
% @param slice_no the slice number desired to be read
% 
% @return raw_frames an array containing raw data frames
% @return chop flag - negate alternate data elements (fftshift)
% @return da_xres - data acquisition size is row dimension
% @return da_yres - data acquisition size in col dimension
% @return gradcoil - gradient type:  BRM, XRMB, XRMW
% @return four_corners - 4 image corner points for gradwarp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [raw_frames, chop, da_xres, da_yres, gradcoil, four_corners] = getChannelData(pfile, slice_no)
    my_slice = slice_no;

    % Open Pfile to read reference scan data.
    fid = fopen(pfile,'r', 'ieee-be');
    if fid == -1
        err_msg = sprintf('Unable to locate Pfile %s', pfile)
        return;
    end
    % Determine size of Pfile header based on Rev number
    status = fseek(fid, 0, 'bof');
    [f_hdr_value, count] = fread(fid, 1, 'real*4');
    rdbm_rev_num = f_hdr_value(1);
    if( rdbm_rev_num == 7.0 )
        pfile_header_size = 39984;  % LX
    elseif ( rdbm_rev_num == 8.0 )
        pfile_header_size = 60464;  % Cardiac / MGD
    elseif (( rdbm_rev_num > 5.0 ) && (rdbm_rev_num < 6.0)) 
        pfile_header_size = 39940;  % Signa 5.5
    else
        % In 11.0 and later the header and data are stored as little-endian
        fclose(fid);
        fid = fopen(pfile,'r', 'ieee-le');
        status = fseek(fid, 0, 'bof');
        [f_hdr_value, count] = fread(fid, 1, 'real*4');
        rdbm_rev_num = f_hdr_value(1);
        if (rdbm_rev_num == 9.0)  % 11.0 product release
            pfile_header_size= 61464;
        elseif (rdbm_rev_num == 11.0)  % 12.0 product release
            pfile_header_size= 66072;
        elseif (rdbm_rev_num > 11.0) & (rdbm_rev_num < 26.0)  
            % For 14.0 to 25.0 Pfile header size can be found here
            status = fseek(fid, 1468, 'bof');
            pfile_header_size = fread(fid,1,'integer*4');   
            status = fseek(fid, 1508, 'bof');
            prescan_offset = fread(fid,1,'integer*4');
        elseif ( rdbm_rev_num >= 26.0) & (rdbm_rev_num < 100.0)  % 26.0 to ??
            % For 26.0 Pfile header size moved to location just after rev num
            status = fseek(fid, 4, 'bof');
            pfile_header_size = fread(fid,1,'integer*4');
            status = fseek(fid, 44, 'bof');
            prescan_offset = fread(fid,1,'integer*4');
        else
            err_msg = sprintf('Invalid Pfile header revision: %f', rdbm_rev_num )
            return;
        end
    end        

    % Read header information
    if (rdbm_rev_num < 26.0 )
        status = fseek(fid, 0, 'bof');
    else
        status = fseek(fid, 76, 'bof'); % skip 76 bytes of data added for 26.0
    end
    [hdr_value, count] = fread(fid, 102, 'integer*2');
    rhtype = hdr_value(29);
    rhformat = hdr_value(30);
    npasses = hdr_value(33);
    nslices = hdr_value(35);
    nechoes = hdr_value(36);
    nframes = hdr_value(38);
    point_size = hdr_value(42);
    da_xres = hdr_value(52);
    da_yres = hdr_value(53);
    rc_xres = hdr_value(54);
    rc_yres = hdr_value(55);
    gradcoil = hdr_value(93);  % Maybe BRM = 5 & XRMW = 0?
    start_recv = hdr_value(101); % not used for 25.0 & greater
    stop_recv = hdr_value(102);

    % Determine number of slices in this Pfile:  this does not work for all cases.
    slices_in_pass = nslices/npasses;

    % Compute size (in bytes) of each frame, echo and slice
    data_elements = da_xres*2*(da_yres-1);
    frame_size = da_xres*2*point_size;
    echo_size = frame_size*da_yres;
    slice_size = echo_size*nechoes;
    mslice_size = slice_size*slices_in_pass;

    % For 24.0 and earlier - nreceivers is determined as follows
    if (rdbm_rev_num < 25.0)
        nreceivers = (stop_recv - start_recv) + 1;
    else % For 25.0 and later - compute nreceivers from number of slices
        status = fseek(fid, 0, 'eof');
        pfile_size = ftell(fid);
        pass_size = (pfile_size - pfile_header_size)/nslices;
        nreceivers = pass_size/mslice_size;
    end

    sum_freq = zeros(da_yres-1, da_xres);

    % Determine number of slices in this Pfile:  this does not work for all cases.
    slices_in_pass = nslices/npasses; 
    if (my_slice > slices_in_pass)
         my_slice = 1;
    end
    msg=sprintf('Number of channels = %d, using slice %d of %d', nreceivers, my_slice, slices_in_pass );
    disp(msg);

    % Read image corner points for Gradwarp
    % Compute offset to where the corner points are stored for this slice
    file_offset = 2048 - (222*2) - (31*4); % offset to data_acq_table 
    status = fseek(fid, file_offset, 'bof');
    slice_info_size = 48;
    [data_acq_table_offset, count] = fread(fid, 1, 'integer*4');
    if (data_acq_table_offset == 0) % Legacy
        data_acq_table_offset = 2048 + 2*4096;  % RDB_HEADER_REC + 2*RDB_PER_PASS_TAB
        slice_info_size = 44; % RDB_SLICE_INFO_ENTRY is 44 bytes
    end
    file_offset = data_acq_table_offset + ((my_slice-1)*slice_info_size) + 4; 
    status = fseek(fid, file_offset, 'bof');
    data_elements = 9;
    [corner_points, count] = fread(fid, data_elements, 'float');
    P1=[corner_points(2); corner_points(1); corner_points(3)];
    P2=[corner_points(5); corner_points(4); corner_points(6)];
    P3=[corner_points(8); corner_points(7); corner_points(9)];

    % Compute the missing corner point from the other 3
    d12= norm(P1-P2)^2;
    d23= norm(P2-P3)^2;
    d31= norm(P3-P1)^2;
    if d12 > d23 && d12 >d31
        A=P3; B= P1; C=P2;
    elseif d23 >d12 && d23 > d31
        A=P1; B=P2; C=P3;
    else
        A=P2; B=P2; C=P1;
    end
    D= B + C - A;
    four_corners = [A,B,C,D]';
    
    % Compute size (in bytes) of each frame, echo and slice
    data_elements = da_xres*2*(da_yres-1);
    frame_size = da_xres*2*point_size;
    echo_size = frame_size*da_yres;
    slice_size = echo_size*nechoes;
    mslice_size = slice_size*slices_in_pass;

    % Select first echo
    my_echo = 1;

    raw_frames = zeros(rc_xres, rc_yres, nreceivers);
    
    for r=1:nreceivers
    % Compute offset in bytes to start of frame.  (skip baseline view)
        file_offset = pfile_header_size + ((r - 1)*mslice_size) + ...
                  + ((my_slice -1)*slice_size) + ...
                  + ((my_echo-1)*echo_size) + ...
                  + (frame_size);

        status = fseek(fid, file_offset, 'bof');

        % read data: point_size = 2 means 16 bit data, point_size = 4 means EDR )
        if (point_size == 2 )
            [raw_data, count] = fread(fid, data_elements, 'integer*2');
        else
            [raw_data, count] = fread(fid, data_elements, 'integer*4');
        end

        %frame_data = zeros(da_xres);
        for j = 1:(da_yres -1)
            row_offset = (j-1)*da_xres*2;
            for m = 1:da_xres
                raw_frames(m,j,r) = raw_data( ((2*m)-1) + row_offset) + i*raw_data((2*m) + row_offset);
            end
        end
    end
    
    fclose(fid);
    
    if (( rhtype == 1) | (rhtype == 64)) % Alteration Vector flag
         chop = 1;
    else
         chop = 0;
    end
     
end