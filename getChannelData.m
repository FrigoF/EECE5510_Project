%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Title: getChannelData.m
% Author: Jason Darby
% Description: Retrieves the raw data frames from a given pfile for 
%               a given slice and channel.
% Note: This file is a modified version of raw_image.m by Fred Frigo
%
% 
% Fred Frigo   - updated Oct 15, 2020 to support 25.0 and 26.0
%
% @param pfile the path to the raw-data file to be read
% @param slice_no the slice number desired to be read
% @param the number of channels to be read 1 or -1
%           if 1, you will be prompted for channel
%           if -1, you will receive all channels
%
% @return an array containing 1 or all of the raw data frames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



function [raw_frames, alternate] = getChannelData(pfile, slice_no, num_channels)
    i = sqrt(-1);
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
    npasses = hdr_value(33);
    nslices = hdr_value(35);
    nechoes = hdr_value(36);
    nframes = hdr_value(38);
    point_size = hdr_value(42);
    da_xres = hdr_value(52);
    da_yres = hdr_value(53);
    rc_xres = hdr_value(54);
    rc_yres = hdr_value(55);
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
    msg=sprintf('Number of channels = %d, using slice %d of %d', nreceivers, slice_no, slices_in_pass );
    disp(msg);
    
    % Compute size (in bytes) of each frame, echo and slice
    data_elements = da_xres*2*(da_yres-1);
    frame_size = da_xres*2*point_size;
    echo_size = frame_size*da_yres;
    slice_size = echo_size*nechoes;
    mslice_size = slice_size*slices_in_pass;

    % Enter slice number to plot
    if ( slices_in_pass > 1 )
        if (my_slice > slices_in_pass)
            err_msg = sprintf('Invalid number of slices. Slice number set to 1.');
            disp(err_msg);
            my_slice = 1;
        end
    end

    % Enter echo number to plot
    my_echo = 1;
    if ( nechoes > 1 )
        echo_msg = sprintf('Enter the echo number: [1..%d]',nechoes);
        my_echo = input(echo_msg);
        if (my_echo > nechoes )
            err_msg = sprintf('Invalid echo number. Echo number set to 1.')
            my_echo = 1;
        end
    end

    if ( num_channels == -1 )
        % Zero pad rows
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
    else
       
        % Zero pad rows
        raw_frames = zeros(rc_xres, rc_yres, 1);
        my_receiver = 1;
        if ( nreceivers > 1 )
            recv_msg = sprintf('Enter the receiver number: [1..%d]',nreceivers);
            my_receiver = input(recv_msg);
            if (my_receiver > nreceivers)
                err_msg = sprintf('Invalid receiver number. Receiver number set to 1.')
                my_receiver = 1;
            end
        end
        file_offset = pfile_header_size + ((my_receiver - 1)*mslice_size) + ...
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
                raw_frames(m,j,1) = raw_data( ((2*m)-1) + row_offset) + i*raw_data((2*m) + row_offset);
            end
        end
    end

    fclose(fid);
    
     if (( rhtype == 1) | (rhtype == 64)) 
         alternate = 1;
     else
         alternate = 0;
     end
     
end