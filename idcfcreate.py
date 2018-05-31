import sys,argparse,glob,os.path
from pyraf import iraf as i
from iraf import stsdas
from astropy.io import fits
from datetime import date

def create(idcfile,prefix,fitsfile='',
    colfile='/grp/hst/acs/dborncamp/pre_sm04/f606w/acswfcquartic_idc_cols.txt'):


   idir=idcfile[0:idcfile.rfind('/')+1] #write to same directory as txt file
   if fitsfile == '':
      fitsfile=idir+idcfile[idcfile.rfind('/')+1:len(idcfile)-4]+'.fits'
   if os.path.isfile(fitsfile): os.remove(fitsfile)
#   print fitsfile
#   print idcfile
#   print colfile
   i.tcreate(fitsfile,colfile,idcfile,nskip=0,nlines=3,nrows=0,hist=True,
	 extrapar=10,extracol=2)


   print fitsfile+' created.'

   editheader(fitsfile,prefix)


def editheader(fitsfile,prefix,hist_file=''):
   
   with fits.open(fitsfile,mode='update') as temp:
       header = temp[0].header
    
       fdir = fitsfile[0:fitsfile.rfind('/')+1]
    
       #get everything between the last occurence of / and second occurance of _ after the last occurance of /
       #prefix=fitsfile[fitsfile.rfind('/')+1:fitsfile.find('_',fitsfile.find('_',fitsfile.rfind('/')+1,len(fitsfile))+1,len(fitsfile))]
       #prefix = fitsfile.rsplit('/')
       print 'looking for files in: '+fdir+prefix+'*'
       #get the file with time dependencies
       cfile=glob.glob(fdir+prefix+'*alltime_coeffs.txt')
       if 'post' in fitsfile:
           post = True
       else:
           post = False
    
       if hist_file=='':
          #post=prefix[prefix.find('_')+1:len(prefix)]
          if 'post' in fitsfile.rsplit('/')[-1]:
              hist_file='/grp/hst/acs/dborncamp/deliver/posthist_idc.txt'
              print 'using history file: '+hist_file
          elif 'pre' in fitsfile.rsplit('/')[-1]:
              hist_file='/grp/hst/acs/dborncamp/deliver/prehist_idc.txt'
              print 'using history file: '+hist_file
          else:
              print '** post is weird, check naming convention!'
              print '** Continuing with default history file.'
              hist_file='/Users/slhoffmann/acs/geodist/dave_grit_repo/idc_transforms_master/hist_idc.txt'
              print '** ' + hist_file
    
    
       if len(cfile)>1: 
          print ''
          print 'there is a problem, more than one coeff file found. quitting.'
          print 'cfiles: '
          print cfile
          return
    
       if len(cfile)==0:
          print '* no time coefficient file found in the txt file directory.'
          print '* trying again'
          print '* looking at default directory.'
          pre_test=prefix.split('_')[-1] #should be pre or pos
          print pre_test
          if pre_test == 'pre':
              timedir='/grp/hst/acs/dborncamp/pre_sm04/all/'
          elif pre_test=='post':
              timedir='/grp/hst/acs/dborncamp/post_sm04/all/'
          else:
              print 'prefix not happy... this file should be date_sm'
              print 'editheader returning...'
              return
          print '* looking at '+timedir+prefix+'*alltime_coeffs.txt'
          cfile=glob.glob(timedir+prefix+'*alltime_coeffs.txt')
          print '*'
          print '* files returned:'
          print cfile
          print ''
    
    
       cfile=cfile[0]
       with open(cfile,'r') as f:
           #take out first 2 lines, dont care about them
           dummy=f.readline()
           dummy=f.readline()
           ztime=float(f.readline().split()[-1])
           yrot_b1=float(f.readline().split()[-1])
           yrot_b2=float(f.readline().split()[-1])
           yrot_a1=float(f.readline().split()[-1])
           yrot_a2=float(f.readline().split()[-1])
           xscl_b1=float(f.readline().split()[-1])
           xscl_b2=float(f.readline().split()[-1])
           xscl_a1=float(f.readline().split()[-1])
           xscl_a2=float(f.readline().split()[-1])
           yscl_b1=float(f.readline().split()[-1])
           yscl_b2=float(f.readline().split()[-1])
           yscl_a1=float(f.readline().split()[-1])
           yscl_a2=float(f.readline().split()[-1])    

       if fitsfile.find('_post') > 0:
          #useafter=('Jan 01 2009 00:00:00','From SM04 to FSW update')
          useafter=('Oct 01 2016 00:00:00','From FSW to present')
          PEDIGREE= 'INFLIGHT 01/06/2002'
          post=True
       #elif fitsfile.find('_11_') > 0:
       #   useafter=('Jun 21 2011 21:00:00','2011 to present')
       else:
          useafter=('Jan 01 2002 00:00:00','From ACS creation to Failure')
          post=False
          PEDIGREE= 'INFLIGHT 01/05/2006'

       header['DETECTOR']='WFC'
       header['INSTRUME']='ACS'
       header['NORDER']=5
       header['PARITY']=-1
       header['FILETYPE']='DISTORTION COEFFICIENTS'
       #header['DESCRIP']='Replaces 02c1450nj to update to correct V2V3REF for all filters.---'
       header['DESCRIP']='Updated polarizer for Flight Software change for subarrays---------'
       header['USEAFTER']=useafter
       header['PEDIGREE']=PEDIGREE
       header['TDD_DATE']=ztime
       header['TDD_CTB1']=(yrot_b1,'Yrotation cy_11')
       header['TDD_CTB2']=(yrot_b2,'Yrotation cy_11')
       #header['TDD_CTA1']=(yrot_a1,'Yrotation cy_11')
       #header['TDD_CTA2']=(yrot_a2,'Yrotation cy_11')
       header['TDD_CXB1']=(xscl_b1,'Xscale cx_11')
       header['TDD_CXB2']=(xscl_b2,'Xscale cx_11')
       #header['TDD_CXA1']=(xscl_a1,'Xscale cx_11')
       #header['TDD_CXA2']=(xscl_a2,'Xscale cx_11')
       #if not post:
           #header['TDD_CYB1']=(yscl_b1,'Yscale cy_10')
           #header['TDD_CYB2']=(yscl_b2,'Yscale cy_10')
           #header['TDD_CYA1']=(yscl_a1,'Yscale cy_10')
           #header['TDD_CYA2']=(yscl_a2,'Yscale cy_10')

       today=date.today()
    
       header['comment'][0]='Created by D. Borncamp, '+today.isoformat()
       header['comment'][1]='Vafactor removed from coefficients'
       header['comment']='TDD terms for ACS/WFC included in header'

       #temp[0].add_checksum()
    
       #temp.close()
    
   i.stsdas.toolbox.headers.stfhistory(fitsfile,'@'+hist_file)
   print fitsfile
   print 'Header updated'

if __name__ == '__main__':

#I dont understand argparse!
#   parser=argparse.ArgumentParser(description='Create an IDCfits table from a text coefficients file. And add keywords to header.')
#   parser.add_argument('idcfile',type=str)
   idcfile=sys.argv[1]
   prefix = sys.argv[2]
   if idcfile == '': print 'idcfile.txt undefined'
   create(idcfile, prefix)
