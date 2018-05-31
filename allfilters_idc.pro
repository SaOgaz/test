;+
;this will get the filter combinations needed for the IDC and output a new txt
;file that can be ingested into idcfcreate to create a new idc file. It will
;populate everything needed with the F606W information. Except for things that
;already have entries in the new idctab as they are already calibrated.
;
;This needs to be run after the IDCTAB for all known filters is made and in
;fits format. This program will use that IDCTAB to make a list of known filters
;and use that to populate the full IDCTAB with all filters.
;
;  !!  This assumes that 606 is the first entry in the idc.txt file!!!
;
;  !! Assumes that the text file has filter1 and filter2 together !!!
;
; Both of these assumptions should be okay if the rest of the pipeline is
;used in its default way
;
; 7/7/15 - DMB - added some smarts to look at current IDCtab and use what is
;                in that instead of replacing everything with 606. Dont know
;                how the distortion with 2 filters will go but for now they all
;                have an entry.
; 11/16/15 - DMB - Can no longer read in old IDCTAB's as they have bad entries
;                so changed it to loop through all filter combinations. This is
;                a big change.
;
; 12/16/15 - DMB - Changed to allow old 4th order solution for ramp filters and
;                polarizers. There should be a better way to do this if
;                starting from scratch. But this seems to work...
;
;-
post=1
verbose=0 ;will print EVERYTHING, use wisely
write=1
fits=1
clobber=0

prefix='020216'

if post then begin 
    sm='post_sm04/' 
    time='post' ;a cluge
    ;knownidcfile='/grp/hst/acs/dborncamp/post_sm04/all/'+prefix+'_post_all_idc.fits'
    ;knowntxtfile='/grp/hst/acs/dborncamp/post_sm04/all/'+prefix+'_post_all_idc.txt'
    knownidcfile='/grp/hst/acs/dborncamp/post_sm04/all/040516_625_22_post_all_idc.fits'
    knowntxtfile='/grp/hst/acs/dborncamp/post_sm04/all/040516_625_22_post_all_idc.txt'
    oldidcfile='/grp/hst/cdbs/jref/v8q1444sj_idc.fits'
endif else begin 
    sm='pre_sm04/'
    time='pre'
    knownidcfile='/grp/hst/acs/dborncamp/pre_sm04/all/'+prefix+'_pre_all_idc.fits'
    knowntxtfile='/grp/hst/acs/dborncamp/pre_sm04/all/'+prefix+'_pre_all_idc.txt'
    oldidcfile='/grp/hst/cdbs/jref/v8q14451j_idc.fits'
endelse

;stick to the same naming convention
;outfile='/grp/hst/acs/dborncamp/'+sm+'all/'+prefix+'_'+time+'_every_idc_2.txt'
outfile='/grp/hst/acs/dborncamp/deliver/'+prefix+'_'+time+'_fsw_idc7.txt'
;outfile='/grp/hst/acs/dborncamp/deliver/'+prefix+'_every_idc7.txt'
;outfile='test_idc.txt'

;f606dir='/grp/hst/acs/dborncamp/'+sm+'/f606w/'
;f606file=f606dir+prefix+'_'+time+'wfc_idc.txt'
print,'reading in: '+knownidcfile
knownidc=mrdfits(knownidcfile,1,/silent)
oldidc=mrdfits(oldidcfile,1,/silent)

;read in the txt file
nlines=FILE_LINES(knowntxtfile)
sarr=STRARR(nlines)
OPENR,unit,knowntxtfile,/GET_LUN
READF,unit,sarr
FREE_LUN,unit

;coefficient arrays
; !!!  assumes 606 is first entry in table  !!!
;this should be the case if the 'pipeline' was run as usual
;
;chip1
f606_1_0=sarr[0]
f606_1_1=sarr[1]
f606_1_2=sarr[2]
;chip2
f606_2_0=sarr[3]
f606_2_1=sarr[4]
f606_2_2=sarr[5]

;get the v2 and v3 reference position for f606 to be used to create
;lines later on
v2ref_1=double(strmid(f606_1_0,70,8))
v3ref_1=double(strmid(f606_1_0,79,8))
v2ref_2=double(strmid(f606_2_0,70,8))
v3ref_2=double(strmid(f606_2_0,79,8))

;all possible combinations from the template file
filter1_5=['CLEAR1L','F555W','F775W','F625W','F550M','F850LP',$
           'F892N','F606W','F502N','G800L','F658N','F475W',$
           'ANY']

filter2_5=['CLEAR2L','F660N','F814W','F435W',$
           'ANY']


filter1_4=['CLEAR1L','CLEAR1S','POL0UV','POL60UV','POL120UV']

filter2_4=['CLEAR2L','CLEAR2S','FR388N','FR423N','FR462N','FR656N','FR716N',$
           'FR782N','POL0V','POL60V','POL120V','FR914M','FR853N','FR931N',$
           'FR459M','FR647M','FR1016N','FR505N','FR551N','FR601N']


;just a list of all possible combinations, dont need all of them, but make them
;all anyway
filter1=['CLEAR1L','F555W','F775W','F625W','F550M','F850LP',$
         'POL0UV','POL60UV','POL120UV',$
         'F892N','F606W','F502N','G800L','F658N','F475W']

filter2=['CLEAR2L','F660N','F814W','FR388N','FR423N',$
         'FR462N','F435W','FR656N','FR716N','FR782N',$
         'CLEAR2S','POL0V','POL60V',$
         'POL120V','FR914M',$
         'FR853N','FR931N','FR459M','FR647M','FR1016N',$
         'FR505N','FR551N','FR601N']

;get the known filters and make sure they are unique
known_filt1=strtrim(knownidc[uniq(knownidc[*].filter1)].filter1)
known_filt2=strtrim(knownidc[uniq(knownidc[*].filter2)].filter2)
known=[known_filt1,known_filt2]

known=known[where(strmatch(strtrim(known),'CLEAR*') eq 0)]
print,'Known filters list ('+strn(n_elements(known))+' filters): '
print,known
print,''

if exists(outfile) and clobber then begin
    print,''
    print,'Overwriting: '+outfile
    print,'Before starting... Be careful with the clobber option.'
    print,''
    file_delete,outfile
endif

if write then begin 
    openw,out,outfile,/get_lun
    print,'writing: '+outfile
endif
counter=0

fmt='(i1,a9,A12, A10, 2I8, 2F10.2, F10.4, F10.5, 2F12.6)'
fmt2='(F16.10,F16.9,19E16.7)'  ; attempt to emmulate the output of readacspoly

for i=0,n_elements(filter1)-1 do begin
    for j=0,n_elements(filter2)-1 do begin
        ;print, filter1[i],' ',filter2[j]
        ;if counter gt 10 then break
        ;change xref and yref for polarizers
        ;normally its a full frame
        xref=2048.0
        yref=1024.0
        xsize=4096
        ysize=2048

        if strcmp('POL',filter1[i],3) eq 1 and strcmp('POL',filter2[j],3) eq 1 then continue
  
        if strcmp('POL',filter1[i],3) eq 1 or strcmp('POL',filter2[j],3) eq 1 then begin
            xref=1024.0
            yref=1024.0
            xsize=2048  ; polarizer is subarray
            ysize=2048  ; this changes slightly
        endif

        ; set some flags to decide which to use, assume its 5th order
        ; 0 is 4th order, 1 is 5th order -2 is something is wrong
        f_1_5 = 1
        f_2_5 = 1

        ;set up the first line
        line1=string(1,'FORWARD',filter1[i],filter2[j],xsize,ysize,xref,$
              yref,v2ref_1,v3ref_1,0.050000000,format=fmt)
        line2=string(2,'FORWARD',filter1[i],filter2[j],xsize,ysize,xref,$
              yref,v2ref_2,v3ref_2,0.050000000,format=fmt)

        z1 = where(filter1[i] eq filter1_5, count1)
        if count1 eq 0 then begin
            z1 = where(filter1[i] eq filter1_4, count1)
            f_1_5=0
        endif else begin
            if verbose then print,filter1[i]+' found'
        endelse
        if count1 eq 0 then begin
            print, 'There is a problem filter1 not found in 4th or 5th list'
            print,'  ',filter1[i]
            f_1_5=-2
        endif

        z2 = where(filter2[j] eq filter2_5, count2)
        if count2 eq 0 then begin
            z2 = where(filter2[j] eq filter2_4, count2)
            f_2_5=0
        endif
        if count2 eq 0 then begin
            print, 'There is a problem filter2 not found in 4th or 5th list'
            print,'  ',filter2[j]
            f_2_5=-2
        endif

        ;print,filter1[i],' ',filter2[j],' ',count1,' ',count2

        if count1 gt 1 or count2 gt 1 then print,'** counts are greater than 1'

        tot=f_1_5+f_2_5

        ; if the total of the flags is 2 then it should be 5th order
        ; if the total is 1 or 0 then it should be 4th order
        ; if it is negative something went wrong
        ; this way if something is in the 4th order array, it will be forced
        ; to use the 4th order
        filtmatch=''
        case 1 of 
          tot eq 2: begin ;5th order
           if where(filter2[j] eq known) ne -1 or where(filter1[i] eq known) ne -1 then begin
               if where(known eq filter2[j]) ne -1 then filtmatch=known[where(known eq filter2[j])] else filtmatch=known[where(known eq filter1[i])]
     
               ;Match the element
               textmatch=where(strmatch(sarr,'*'+filtmatch+'*'),nmatched)
               if nmatched gt 2 then begin
                   print,'More then one set of matches found, taking first one.'
                   print,textmatch
               endif
              textmatch=textmatch[0] ;just take the first hit...
     
               if verbose then print,'Matched: '+filtmatch+' to '+filter1[i]+' '+filter2[j],textmatch
     
               ;write both chips at the same time now, different from pervious version

               split1=strsplit(sarr[textmatch],' ',/extract)
               split2=strsplit(sarr[textmatch+3],' ',/extract)
               v2ref_1 = split1[8]
               v3ref_1 = split1[9]
               v2ref_2 = split2[8]
               v3ref_2 = split2[9]

               line1=string(1,'FORWARD',filter1[i],filter2[j],xsize,ysize,xref,$
                            yref,v2ref_1,v3ref_1,0.050000000,format=fmt)
               line2=string(2,'FORWARD',filter1[i],filter2[j],xsize,ysize,xref,$
                            yref,v2ref_2,v3ref_2,0.050000000,format=fmt)
               ;need to change the first line to match filter combination
               if verbose then begin 
                   print,line1,' tot: ',tot
                   print,sarr[textmatch+1:textmatch+2]
                   ;print,sarr[textmatch:textmatch+2]
                   print,line2,' tot: ',tot
                   print,sarr[textmatch+4:textmatch+5]
                   ;print,sarr[textmatch+3:textmatch+5]
     
               endif
     
               if write then begin
                   printf,out,line1
                   printf,out,sarr[textmatch+1:textmatch+2]
                   ;printf,out,sarr[textmatch:textmatch+2]
                   printf,out,line2
                   printf,out,sarr[textmatch+4:textmatch+5]
                   ;printf,out,sarr[textmatch+3:textmatch+5]
               endif
     
           endif else begin ;the filter is not known
               ;insert the 606 solution but we need a new first line to say the
               ;correct filter. We do need to use the v2 and v3 ref with this
     
               if verbose then begin
                   print,'Inserting 606 solution for '+filter1[i]+' x '+filter2[j]
                   ;chip1
                   print,line1,' tot: ',tot
                   print,f606_1_1
                   print,f606_1_2
                   ;chip2
                   print,line2,' tot: ',tot
                   print,f606_2_1
                   print,f606_2_2
                   print,''
               endif
     
               ;Make a new first line then print the 606 solution
               if write then begin
                   ;chip1
                   printf,out,line1
                   printf,out,f606_1_1
                   printf,out,f606_1_2
                   ;chip2
                   printf,out,line2
                   printf,out,f606_2_1
                   printf,out,f606_2_2
               endif
           endelse ;end not known
         end ;end 5th order case
         (tot gt -1) and (tot lt 2): begin ;4th order 0 to 1
             z_4=where(strtrim(oldidc.filter1) eq filter1[i] and strtrim(oldidc.filter2) eq filter2[j], z_4_count)

             if z_4_count lt 2 then begin
                 print,''
                 print,' *******'
                 print,' There is a problem finding this entry in the oldidc'
                 print,filter1[i],' ',filter2[j]
                 print,' *** please check it'
                 print,''
                 break
             endif

             if verbose then begin
                 print,line1,' tot: ',tot
                 print,oldidc[z_4[0]].cx10,oldidc[z_4[0]].cx11,oldidc[z_4[0]].cx20,oldidc[z_4[0]].cx21,oldidc[z_4[0]].cx22,oldidc[z_4[0]].cx30,oldidc[z_4[0]].cx31,oldidc[z_4[0]].cx32,oldidc[z_4[0]].cx33,oldidc[z_4[0]].cx40,oldidc[z_4[0]].cx41,oldidc[z_4[0]].cx42,oldidc[z_4[0]].cx43,oldidc[z_4[0]].cx44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2
                 print,oldidc[z_4[0]].cy10,oldidc[z_4[0]].cy11,oldidc[z_4[0]].cy20,oldidc[z_4[0]].cy21,oldidc[z_4[0]].cy22,oldidc[z_4[0]].cy30,oldidc[z_4[0]].cy31,oldidc[z_4[0]].cy32,oldidc[z_4[0]].cy33,oldidc[z_4[0]].cy40,oldidc[z_4[0]].cy41,oldidc[z_4[0]].cy42,oldidc[z_4[0]].cy43,oldidc[z_4[0]].cy44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2

                 print,line2,' tot: ',tot
                 print,oldidc[z_4[1]].cx10,oldidc[z_4[1]].cx11,oldidc[z_4[1]].cx20,oldidc[z_4[1]].cx21,oldidc[z_4[1]].cx22,oldidc[z_4[1]].cx30,oldidc[z_4[1]].cx31,oldidc[z_4[1]].cx32,oldidc[z_4[1]].cx33,oldidc[z_4[1]].cx40,oldidc[z_4[1]].cx41,oldidc[z_4[1]].cx42,oldidc[z_4[1]].cx43,oldidc[z_4[1]].cx44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2
                 print,oldidc[z_4[1]].cy10,oldidc[z_4[1]].cy11,oldidc[z_4[1]].cy20,oldidc[z_4[1]].cy21,oldidc[z_4[1]].cy22,oldidc[z_4[1]].cy30,oldidc[z_4[1]].cy31,oldidc[z_4[1]].cy32,oldidc[z_4[1]].cy33,oldidc[z_4[1]].cy40,oldidc[z_4[1]].cy41,oldidc[z_4[1]].cy42,oldidc[z_4[1]].cy43,oldidc[z_4[1]].cy44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2

             endif

             if write then begin
                 printf,out,line1
                 printf,out,oldidc[z_4[0]].cx10,oldidc[z_4[0]].cx11,oldidc[z_4[0]].cx20,oldidc[z_4[0]].cx21,oldidc[z_4[0]].cx22,oldidc[z_4[0]].cx30,oldidc[z_4[0]].cx31,oldidc[z_4[0]].cx32,oldidc[z_4[0]].cx33,oldidc[z_4[0]].cx40,oldidc[z_4[0]].cx41,oldidc[z_4[0]].cx42,oldidc[z_4[0]].cx43,oldidc[z_4[0]].cx44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2
                 printf,out,oldidc[z_4[0]].cy10,oldidc[z_4[0]].cy11,oldidc[z_4[0]].cy20,oldidc[z_4[0]].cy21,oldidc[z_4[0]].cy22,oldidc[z_4[0]].cy30,oldidc[z_4[0]].cy31,oldidc[z_4[0]].cy32,oldidc[z_4[0]].cy33,oldidc[z_4[0]].cy40,oldidc[z_4[0]].cy41,oldidc[z_4[0]].cy42,oldidc[z_4[0]].cy43,oldidc[z_4[0]].cy44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2

                 printf,out,line2
                 printf,out,oldidc[z_4[1]].cx10,oldidc[z_4[1]].cx11,oldidc[z_4[1]].cx20,oldidc[z_4[1]].cx21,oldidc[z_4[1]].cx22,oldidc[z_4[1]].cx30,oldidc[z_4[1]].cx31,oldidc[z_4[1]].cx32,oldidc[z_4[1]].cx33,oldidc[z_4[1]].cx40,oldidc[z_4[1]].cx41,oldidc[z_4[1]].cx42,oldidc[z_4[1]].cx43,oldidc[z_4[1]].cx44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2
                 printf,out,oldidc[z_4[1]].cy10,oldidc[z_4[1]].cy11,oldidc[z_4[1]].cy20,oldidc[z_4[1]].cy21,oldidc[z_4[1]].cy22,oldidc[z_4[1]].cy30,oldidc[z_4[1]].cy31,oldidc[z_4[1]].cy32,oldidc[z_4[1]].cy33,oldidc[z_4[1]].cy40,oldidc[z_4[1]].cy41,oldidc[z_4[1]].cy42,oldidc[z_4[1]].cy43,oldidc[z_4[1]].cy44,0.0,0.0,0.0,0.0,0.0,0.0,format=fmt2

             endif
          end ;end 4th order
          tot lt 0: begin
            print,'There is a problem!!!'
            print,'*** '+filter1[i]+','+filter2[j],' Tot: ',tot
          end

        else: begin
            print,'***'
            print,''
            print,'Nothing found. tot: ',tot
            print,''
            end
        endcase
        counter++
    endfor
endfor

if write then free_lun,out

print,''
print,'Created '+strn(counter)+' combinations'
print,''

if fits and write then begin 
    print,'spawning...'
    spawn,'/Users/dborncamp/miniconda2/envs/iraf27/bin/python /grp/hst/acs/dborncamp/idcfcreate.py '+outfile + ' ' + prefix+'_'+time


    ;spawn,'/Users/dborncamp/STScI/ssbx_110515/variants/common/bin/python /grp/hst/acs/dborncamp/idcfcreate.py '+outfile
print,''
print,outfile+' turned into .fits file.'
endif

end
