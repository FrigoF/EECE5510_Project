% read_receiver_weights.m  -  read prescan noise weights from Pfile
%
% Author: Fred J. Frigo
% Date:  Mar 11, 2008
%        Oct 15, 2020 - updated for 26.0 and later
%
%

function [weights] = read_weights( pfile )
    % Check to see if pfile name was passed in
    if ( nargin == 0 )
       % Enter name of Pfile
       [fname, pname] = uigetfile('*.*', 'Select Pfile');
       pfile = strcat(pname, fname);
    end
    i = sqrt(-1);

    % Open Pfile to read reference scan data.
    fid = fopen(pfile,'r', 'ieee-le');
    if fid == -1
        err_msg = sprintf('Unable to locate Pfile %s', pfile)
        return;
    end

    % Determine size of Pfile header based on Rev number
    [rdbm_rev_num, count] = fread(fid, 1, 'real*4');

    num_receivers = 16;

    % Determine number of channels and recon scale factor.
    if (rdbm_rev_num >= 9.0) & (rdbm_rev_num < 100.0)
        status = fseek(fid, 168, 'bof');
        rational_scale_factor = fread(fid,1,'real*4');
        status = fseek(fid, 200, 'bof');
        start_recv = fread(fid,1,'integer*2');
        stop_recv = fread(fid,1,'integer*2');
        num_receivers = stop_recv - start_recv + 1;
    else
        err_msg = sprintf('Invalid Pfile header revision: %f', f_hdr_value );
        disp(err_msg);
    end  

    if (rdbm_rev_num == 9.0) |  (rdbm_rev_num < 12.0) % 11.0 + 12.0
        status = fseek(fid, 792, 'bof');
        [receiver_weights, count] = fread(fid,num_receivers,'real*4');  % 16 Max
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
        err_msg = sprintf('Invalid Pfile header revision: %f', rdbm_rev_num );
        disp(err_msg);
        return;
    end       
           
    % Read header information
    if (rdbm_rev_num < 26.0 )
        status = fseek(fid, 0, 'bof');
    else
        status = fseek(fid, 76, 'bof'); % skip 76 bytes of data added for 26.0
    end
    [hdr_value, count] = fread(fid, 102, 'integer*2');
    npasses = hdr_value(33);
    nslices = hdr_value(35);
    nechoes = hdr_value(36);
    nframes = hdr_value(38);
    point_size = hdr_value(42);
    da_xres = hdr_value(52);
    da_yres = hdr_value(53);
    rc_xres = hdr_value(54);
    rc_yres = hdr_value(55);
    start_recv = hdr_value(101);  % not used for 25.0 & later
    stop_recv = hdr_value(102);

    % For 24.0 and earlier - nreceivers is determined as follows
    if (rdbm_rev_num < 25.0)
        nreceivers = (stop_recv - start_recv) + 1;
        status = fseek(fid, 1508, 'bof');
        prescan_offset = fread(fid,1,'integer*4');
        coil_weight_offset = prescan_offset + 332;
        autoshim_offset = prescan_offset + 320;
        status = fseek(fid, autoshim_offset, 'bof');
        [autoshim, count] = fread(fid,3,'integer*2');
        status = fseek(fid, coil_weight_offset, 'bof');
        [receiver_weights, count] = fread(fid,num_receivers,'real*4');  % 128 Max
    else % For 25.0 and later - compute nreceivers from prescan noise data
        nreceivers = 0;
        max_num_receivers = 128;
        coil_weight_offset = prescan_offset + 332;
        status = fseek(fid, coil_weight_offset, 'bof');
        [psc_receiver_weights, count] = fread(fid,max_num_receivers,'real*4');  % 128 Max
        % Determine number of receivers for 25.0 and later from receiver weights
        noise_threshold = psc_receiver_weights(max_num_receivers) + 1.0;
        for psc_rec = 1:max_num_receivers
            if ( psc_receiver_weights(psc_rec) >= noise_threshold) 
                nreceivers = nreceivers + 1;
                receiver_weights(psc_rec)=psc_receiver_weights(psc_rec);
            end
        end
    end
    fclose(fid);

    sum(receiver_weights);

    avg_rec_std = sum(receiver_weights)./size(receiver_weights,1);
    weights = receiver_weights./avg_rec_std;

   if( num_receivers > 1 )
      figure;
      plot(weights);
      title('Receiver Weights');
   end
end