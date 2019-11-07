% plotp.m  -  plot raw data from Pfile
%
% Marquette University,   Milwaukee, WI  USA
% Copyright 2002, 2003 - All rights reserved.
% Fred Frigo
%
% Date:  Jan 21, 2002 
%
%   - this is based on MATLAB code from David Zhu - checkRaw.m
%   - updated May 14, 2003 to support 11.0 (little endian format)
%   - updated April 26, 2004 to support 12.0
%   - updated July 15, 2016 to support 25.0 and 26.0
%

function plotp( pfile )

i = sqrt(-1);


if(nargin == 0)
    [fname, pname] = uigetfile('*.*', 'Select Pfile');

    pfile = strcat(pname, fname);
end

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
        end
    end
end


% Specto Prescan pfiles 
if (da_xres == 1) & (da_yres == 1)
   da_xres = 2048; 
end

% Determine number of slices in this Pfile:  this does not work for all cases.
slices_in_pass = nslices/npasses;

% Compute size (in bytes) of each frame, echo and slice
data_elements = da_xres*2;
frame_size = data_elements*point_size;
echo_size = frame_size*da_yres;
slice_size = echo_size*nechoes;
mslice_size = slice_size*slices_in_pass;

for k = 500:1000		% give a large number 1000 to loop forever
  % Enter slice number to plot
  if ( slices_in_pass > 1 )
      slice_msg = sprintf('Enter the slice number: [1..%d]',slices_in_pass); 
      my_slice = input(slice_msg);
      if (my_slice > slices_in_pass)
          err_msg = sprintf('Invalid number of slices. Slice number set to 1.')
          my_slice = 1;
      end
  else
      my_slice = 1;
  end
  
  % Enter echo number to plot
  if ( nechoes > 1 )
      echo_msg = sprintf('Enter the echo number: [1..%d]',nechoes);
      my_echo = input(echo_msg);
      if (my_echo > nechoes )
          err_msg = sprintf('Invalid echo number. Echo number set to 1.')
          my_echo = 1;
      end
  else
      my_echo = 1;
  end
  
  % Enter receiver number to plot
  if ( nreceivers > 1 )
      recv_msg = sprintf('Enter the receiver number: [1..%d]',nreceivers);
      my_receiver = input(recv_msg);
      if (my_receiver > nreceivers)
          err_msg = sprintf('Invalid receiver number. Receiver number set to 1.')
          my_receiver = 1;
      end      
  else
      my_receiver = 1;
  end

  % Enter the view number
  view_msg = sprintf('Enter the frame number (1 is baseline): [1..%d]',da_yres);
  my_frame = input(view_msg);
  if (my_frame > da_yres)
      err_msg = sprintf('Invalid frame number. Frame number set to 1.')
      my_frame = 1;
  end      

  % Compute offset in bytes to start of frame.
  file_offset = pfile_header_size + ((my_slice - 1)*slice_size) + ...
                      + ((my_receiver -1)*mslice_size) + ...
                      + ((my_echo-1)*echo_size) + ...
                      + ((my_frame-1)*frame_size);
   
  status = fseek(fid, file_offset, 'bof');

  % read data: point_size = 2 means 16 bit data, point_size = 4 means EDR )
  if (point_size == 2 )
     [raw_data, count] = fread(fid, data_elements, 'integer*2');
  else
      [raw_data, count] = fread(fid, data_elements, 'integer*4');
  end

  for m = 1:da_xres
     frame_data(m) = raw_data((2*m)-1) + i*raw_data(2*m);
  end
  
  figure(k);
  subplot(3,1,1);
  plot(real(frame_data));
  title(sprintf('%s, slice %d, recv %d, echo %d, frame %d', fname, my_slice, my_receiver, my_echo, my_frame));
  %title('Reference data');
  xlabel('time');
  ylabel('Real');
  subplot(3,1,2);
  plot(imag(frame_data));
  %title(sprintf('Imaginary Data'));
  xlabel('time');
  ylabel('Imaginary');
  subplot(3,1,3);
  plot(abs(frame_data));
  %title(sprintf('Magnitude Data'));
  xlabel('time');
  ylabel('Magnitude');


  % check to see if we should quit
  quit_answer = input('Press Enter to continue, "q" to quit:', 's');
  if ( size( quit_answer ) > 0 )
     if (quit_answer == 'q')
         break;
     end
  end
  
end
fclose(fid);