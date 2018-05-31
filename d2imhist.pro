oldfile='deliver/acs_230115_d2im.fits'
newfile='deliver/wfc_update3_d2im.fits'

if exists(newfile) then file_delete,newfile

histfile='deliver/d2imhist.txt'

;get a good file name to stick into the filename keyword
rootfile=strmid(newfile,strpos(newfile,'/',/REVERSE_SEARCH)+1,strlen(newfile))

;get the existing things
main_hdr=headfits(oldfile,/silent)
data=mrdfits(oldfile,1,hdr1,/silent)
hdr=''

;read in the history file
openr,lun,histfile,/get_lun
hist=''
line=''

WHILE NOT EOF(lun) DO BEGIN & $
  READF, lun, line & $
  hist = [hist, line] & $
ENDWHILE
free_lun,lun

;for some reason there is weird spaving of the comments
;take out the empty strings from the header
for i=0,n_elements(hdr)-1 do begin
    ;not 80 character empty string...
    if main_hdr[i] ne '                                                                                ' then hdr=[hdr,main_hdr[i]]
endfor

;remove the first starting ''
hdr=hdr[1:-1]

;delete things
sxdelpar,hdr,'IRAF-TLM'
sxdelpar,hdr,'ORIGIN'

;add everything to the header
sxaddpar,hdr,'FILENAME',rootfile,'Name of file'
sxaddpar,hdr,'FILETYPE','WFC D2I FILE','Type of data found in data file'
sxaddpar,hdr,'OBSTYPE','IMAGING ','Type of observation '
sxaddpar,hdr,'DESCRIP','Non-polynomial filter dependent distortion file for ACS/WFC'
sxaddpar,hdr,'USEAFTER','Mar 01 2002 00:00:00'
sxaddpar,hdr,'PEDIGREE','INFLIGHT 11/11/2002'
sxaddpar,hdr,'TELESCOP','HST'
sxaddpar,hdr,'INSTRUME','ACS'
sxaddpar,hdr,'DETECTOR','WFC'
sxaddpar,hdr,'COMMENT','Original D2IMFILE derivation by V.Kozhurina-Platais'
sxaddpar,hdr,'COMMENT','NPOL header updated by D. Borncamp 10 Jul 2015'

sxaddhist,hist,hdr

;write it out
mwrfits,0,newfile,hdr
mwrfits,data,newfile,hdr1,/silent

end
