import glob
import os
import matplotlib.pyplot as plt
from matplotlib.ticker import NullFormatter
from astropy.io import fits
from astropy.io import ascii
from astropy.table import Table
import numpy as np

'''
This is a compialtion of functions that make plots out of a match files
produced from tweakreg. This program is not robust, but works for the most
part which is all that is really needed.

Initially created on 12/15/13 by Dave Borncamp - my first python program! :)

version 0.1.5 has a lot more documentation.
version 0.2.0 adds in reporting of polynomial fit information in rplot
'''

__version__ = '0.2.0'
__author__ = 'Dave Borncamp'


def many_rplot(searchPattern, verbose=False, save=True, corder=2, overlay=True,
      forceMinMax=True, xrange=False, alpha=0.2, interactive=False,
      xsize=10, ysize=6.75, residmax=0.45, residmin=-0.45):
   '''
   calls the rplot function for each match file found. Will pass many arguments
   to it.

   Returns:
   None

   Input:
   searchPattern - A pattern to search for match files to feed to rplot()


   keywords:
   verbose - Print a lot to the screen. default: False

   save - Will save the plots using the automatic savename. default:True

   corder - Order to fit the scatter plot with. default: 2

   overlay - will overplot the fitted line. Sometimes you dont want a line fit
      so it is nice to be able to turn it off. default: True

   forceMinMax - Will force the min and maximum of the residual plot to be same
      in both X and Y. This is very convient for compairing the different
      pannels in the plot. default: True

   xrange - will force the xrage for the plots to be between -2000 and +2000.
      some versions of TweakReg had issues with how it defined the positions
      of the points so this will make sure that you are looking at the same
      range each time. default: False

   alpha - Transparency of the points in the plot. Very useful for trying to
   find multiple overlaping distrubutions. default: 0.2

   interactive - create and leave an interactive plotting window. could be 
      useful to play with and zoom into certain parts, but be careful as this
      will leave every plot on the screen and not properly close the plot so it
      will eat a lot of memory if using multiple plots. default:False

   xsize - xsize of plot in inches. default: 10

   ysize - ysize of plot in inches. default: 6.75
   '''
   # '*_catalog_fit.match'
   matches = glob.glob(searchPattern)
   if verbose: print 'found files:'
   if verbose: print matches

   if len(matches) == 0: print 'nothing matched for '+searchPattern
   else:
      for match in matches:
         if verbose: print '  Automaticly running rplot for: '+match
         rplot(match, v=verbose, save=save, corder=corder, overlay=overlay,
   	       forceMinMax=forceMinMax, xrange=xrange, residmin=residmin,
               alpha=alpha, interactive=interactive, residmax=residmax,
               xsize=xsize, ysize=ysize)


def rplot(matchfile, xsize=10, ysize=6.75, xrmspos=.1, yrmspos=.1, v=False, corder=1,
      overlay=True, forceMinMax=True, save=False, savename=None, figNum=None,
      xrange=True, residmax=0.45, residmin=-0.45, alpha=0.2,
      interactive=True, coeffName=None):
   '''
   plot residuals. Only one match file at a time.

   just give it a match file and its off. 

   Returns:
   None

   Input:
   matchfile - a matchfile to parse


   keywords:
   xsize - xsize of plot in inches. default: 10

   ysize - ysize of plot in inches. default: 6.75

   xrmspos - the location on the plot where the xrms will be printed. May need
      to be moved if changin printed precision. default:.1
   
   yrmspos - the location on the plot where the yrms will be printed. May need
      to be moved if changin printed precision. default:.1

   v - verbose - Print a lot to the screen. default: False

   corder - Order to fit the scatter plot with. default: 1

   overlay - will overplot the fitted line. Sometimes you dont want a line fit
      so it is nice to be able to turn it off. default: True

   forceMinMax - Will force the min and maximum of the residual plot to be same
      in both X and Y. This is very convient for compairing the different
      pannels in the plot. default: True

   save - Will save the plots using the automatic savename. default:True

   savename - the name to save the figure. if it is an empty string it will
      automaticly create a name to save the figure to which is something like:
      name=matchfile.rsplit('_')[-4].rsplit('/')[-1]+'.png' and it will put it
      in the same directory as the given match file. default: ''

   fignum - the figure number to use for plotting. Useful if trying to compare
      2 different interactive windows and not wanting to make too many. If
      it is None then it will just increment off the next number after the last
      figure. default:None

   xrange - will force the xrage for the plots to be between -2000 and +2000.
      some versions of TweakReg had issues with how it defined the positions
      of the points so this will make sure that you are looking at the same
      range each time. default: False

   residmax - the upper limit to use for plotting the residuals. default:0.45
   
   residmin - the lower limit to use for plotting the residuals. defautl:-0.45

   alpha - Transparency of the points in the plot. Very useful for trying to
      find multiple overlaping distrubutions. default: 1.0 (no transpenecncy)

   interactive - create and leave an interactive plotting window. could be 
      useful to play with and zoom into certain parts, but be careful as this
      will leave every plot on the screen and not properly close the plot so it
      will eat a lot of memory if using multiple plots. default:True


   '''
   
   #get the data. Read in as numpy array
   a = np.genfromtxt(matchfile)
   x = a[..., 0]
   y = a[..., 1]
   xresid = a[..., 6]
   yresid = a[..., 7]

   xmin = x.min()
   xmax = x.max()
   ymin = y.min()
   ymax = y.max()

   xrmax = xresid.max()
   xrmin = xresid.min()
   yrmax = yresid.max()
   yrmin = yresid.min()
   if forceMinMax:
      xrmax = residmax
      xrmin = residmin
      yrmax = residmax
      yrmin = residmin
      if xrange:
         if xmin>-2000: xmin = -2000
         if xmax<2000: xmax = 2000
         if ymin>-2000: ymin = -2000
         if ymax<2000: ymax = 2000

   if v: 
      print xmin, xmax, ymin, ymax
   if v:
      print xrmin, xrmax, yrmin, yrmax
   
   xrms = np.sqrt(abs(np.mean(xresid**2)))
   yrms = np.sqrt(abs(np.mean(yresid**2)))

   # Make the table to store the coeffs
   # make the names correct
   names = ['plot', 'rank']
   types = ['S5','f4']
   for i in range(corder + 1):
       names.append('coeff' + str(i))
       types.append('f8')
   coeffTab = Table(names=names, dtype=types)

   #decide to display or close
#   if interactive: 
#       #print 'interactive'
#       import matplotlib.pyplot as plt
#       import matplotlib
#       matplotlib.use('TkAgg')
#       plt.ion()
#   else: 
#       #print 'else'
#       import matplotlib.pyplot as plt
#       import matplotlib
#       matplotlib.use('Agg')
#       plt.ioff()


   plt.figure(num=figNum, figsize=(xsize, ysize), frameon=True) #resize the plotting area (in inches)


   #top left
   plt.title(matchfile)
   plt.subplots_adjust(left=.11, right=.96, top=.94, bottom=.09, wspace=.19, hspace=.24)
   plt.subplot(221) #2x2 plot grid, first plot
   plt.ylabel('DX (pix)')
   plt.axis([xmin, xmax, xrmin, xrmax])
   plt.locator_params(axis='x', nbins=8)
   plt.scatter(x, xresid, marker='.',  alpha=alpha)
   if overlay:
      coeffs = np.polyfit(x, xresid, corder, full=True) #fit the data, generate coefficients
      poly = np.poly1d(coeffs[0]) #generate a poly1d object to hold coefficients
      xp = np.linspace(xmin, xmax, 2000) #generate a new x data to plot against
      plt.plot(xp, poly(xp), 'y-', lw=2.5) #plot the new line vs 1d function of new line, change the line width to 2.5
      coeffTab.add_row(['X_DX', corder] + list(coeffs[0]))
   plt.axhline(color='r')


   #top right
   plt.subplot(222) #2x2 plot 2nd plot
   plt.axis([ymin, ymax, xrmin, xrmax]) #change range of axis
   plt.locator_params(axis='x', nbins=8) #change spacing of x tickmarcs
   plt.scatter(y, xresid, marker='.', alpha=alpha) #make a scatter plot
   if overlay:
      coeffs = np.polyfit(y, xresid, corder, full=True) 
      poly = np.poly1d(coeffs[0]) 
      xp = np.linspace(ymin, ymax, 2000) 
      plt.plot(xp, poly(xp), 'y-', lw=2.5)
      coeffTab.add_row(['Y_DX', corder] + list(coeffs[0]))
      
   plt.axhline(color='r') #make a horizontal red line after the overlay

   #bottom left
   plt.subplot(223)
   plt.ylabel('DY (pix)')
   plt.xlabel('X (pix)')
   plt.axis([xmin, xmax, yrmin, yrmax])
   plt.locator_params(axis='x', nbins=8)
   plt.scatter(x, yresid, marker='.',  alpha=alpha)
   if overlay:
      coeffs = np.polyfit(x, yresid, corder, full=True) 
      poly = np.poly1d(coeffs[0]) 
      xp = np.linspace(xmin, xmax, 2000) 
      plt.plot(xp, poly(xp), 'y-', lw=2.5) 
      coeffTab.add_row(['X_DY', corder] + list(coeffs[0]))
      
   plt.axhline(color='r')

   plt.text(xmin+(abs(xmin)*xrmspos), yrmax+(yrmax*xrmspos),
	 'Xrms: '+str(xrms)[0:5]+'  #Sources: '+str(x.size))

   #bottom right
   plt.subplot(224)
   plt.xlabel('Y (pix)')
   plt.axis([ymin, ymax, yrmin, yrmax])
   plt.locator_params(axis='x', nbins=8)
   plt.scatter(y, yresid, marker='.', alpha=alpha)
   if overlay:
      coeffs = np.polyfit(y, yresid, corder, full=True) 
      poly = np.poly1d(coeffs[0])
      xp = np.linspace(ymin, ymax, 2000) 
      plt.plot(xp, poly(xp), 'y-', lw=2.5)
      coeffTab.add_row(['Y_DY', corder] + list(coeffs[0]))
      
   plt.axhline(color='r')

   plt.suptitle(matchfile, size='large')

   plt.text(ymin+(abs(ymin)*yrmspos), yrmax+(yrmax*yrmspos),
            'Yrms: '+str(yrms)[0:5])
   
   #figure out a good name for the plot automaticly
   if (savename is None) & (save):
      directory = os.path.dirname(os.path.realpath(matchfile))+'/'
      #print directory
      #print matchfile
      if directory.find('notdd') > 0:
         ending = '_notdd.png'
      elif directory.find('tdd') > 0:
         ending = '_tdd.png'
      elif directory.find('orig') > 0:
         ending = '_orig.png'
      else:
         ending = '_res.png'

      #assumes _catalog_fit.match at end
      #savename = matchfile[0:matchfile.rfind('_',0,len(matchfile)-18)]+'.png'
      name = matchfile.rsplit('_')[-4].rsplit('/')[-1] + ending
      savename = directory + name

      if v:
         print 'savename is automatic: '+savename

   if (coeffName is None) & (save):
      coeffName = directory + matchfile.rsplit('_')[-4].rsplit('/')[-1] + '_fit.dat'
   #write the file
   if save: 
      if os.path.isfile(savename):
         os.remove(savename) 
      if os.path.isfile(coeffName):
         os.remove(coeffName)
 
      print '  saving file: '+savename
      plt.savefig(savename)

      # save the coeffTab
      print "  Saving file: {}".format(coeffName)
      coeffTab.write(coeffName, format='ascii')


   #decide to display or close
   if interactive: 
      plt.ion()
      plt.show()
   else: 
      plt.clf()
      plt.close()
      #matplotlib.use('TkAgg') #leave in a nice state

   
def many_vplot(searchPattern, verbose=False, save=True, arrowlen=0, 
        xsize=10, ysize=10, xbpix=128, ybpix=128, arwscale=200, savename='', 
        interactive=False):
   '''
   will call vplot for any matchfile found using searchPattern.


   Returns:
   None

   Input:
   searchPattern - A pattern to search for match files to feed to vplot()


   keywords:
   verbose - Print a lot to the screen. default: False

   save - Will save the plots using the automatic savename. default:True

   arrowlen - Length of arrows to use for the quivver plot. Can be very useful
      to have similar arrow lengths when trying to compare different plots or
      when the residuals are extremely high. If left to 0 it will compute its
      own length of arrowlen=round((np.sqrt(xresid**2 + yresid**2).max())/2,3).
      Where xresid and yresid are the residual values found in the matchfile.
      This can be kind of bad if there is one really bad residual in the file,
      it can make all of the other arrows really small. use arwscale to try to
      correct for this. default: 0 (automatic)

   xsize - xsize of plot in inches. default: 10

   ysize - ysize of plot in inches. default: 6.75

   xbpix - number of pixels in a bin for the X axis.

   ybpix - number of pixels in a bin for the Y axis.

   arwscale - A scale factor to apply to the arrowlength when making the quiver
      plot. escentially scale=arrowlen/arwscale in the quiver call. this cannot
      be 0. default:200

   savename - the name to save the figure. if it is an empty string it will
      automaticly create a name to save the figure to which is something like:
      name=matchfile.rsplit('_')[-4].rsplit('/')[-1]+'.png' and it will put it
      in the same directory as the given match file. default: ''

   interactive - create and leave an interactive plotting window. could be 
      useful to play with and zoom into certain parts, but be careful as this
      will leave every plot on the screen and not properly close the plot so it
      will eat a lot of memory if using multiple plots. default:False

   '''
      
   #'*_catalog_fit.match'
   matches = glob.glob(searchPattern)
   if verbose:
       print 'found files:'
       print matches

   if len(matches) == 0: print 'Nothing matched for '+searchPattern
   else:
      for match in matches:
          if verbose: print '\n  Automaticly running rplot for: '+match
          vplot(match, verbose=verbose, xsize=xsize, ysize=ysize, arwscale=arwscale, 
               xbpix=xbpix, ybpix=ybpix, arrowlen=arrowlen, save=save, 
               savename=savename, interactive=interactive)



def vplot(matchfile, xsize=10, ysize=10, xbpix=128, ybpix=128, arwscale=200,
        verbose=False, arrowlen=0, save=False, savename='',
        interactive=True):

   '''
   plot binned vectors. Only one match file at a time.

   Tries to be smart about the savename in the same way that rplot would be.


   Returns:
   None


   Input:
   matchfile -  a matchfile to parse


   keywords:

   xsize - xsize of plot in inches. default: 10

   ysize - ysize of plot in inches. default: 6.75

   xbpix - number of pixels in a bin for the X axis.

   ybpix - number of pixels in a bin for the Y axis.

   arwscale - A scale factor to apply to the arrowlength when making the quiver
      plot. escentially scale=arrowlen/arwscale in the quiver call. this cannot
      be 0. default:200

   verbose - Print a lot to the screen. default: False

   arrowlen - Length of arrows to use for the quivver plot. Can be very useful
      to have similar arrow lengths when trying to compare different plots or
      when the residuals are extremely high. If left to 0 it will compute its
      own length of arrowlen=round((np.sqrt(xresid**2 + yresid**2).max())/2,3).
      Where xresid and yresid are the residual values found in the matchfile.
      This can be kind of bad if there is one really bad residual in the file,
      it can make all of the other arrows really small. use arwscale to try to
      correct for this. default: 0 (automatic)

   save - Will save the plots using the automatic savename. default:False

   savename - the name to save the figure. if it is an empty string it will
      automaticly create a name to save the figure to which is something like:
      name=matchfile.rsplit('_')[-4].rsplit('/')[-1]+'.png' and it will put it
      in the same directory as the given match file. default: ''

   interactive - create and leave an interactive plotting window. could be 
      useful to play with and zoom into certain parts, but be careful as this
      will leave every plot on the screen and not properly close the plot so it
      will eat a lot of memory if using multiple plots. default:True
      
   '''
#   if interactive: 
#       #print 'interactive'
#       import matplotlib
#       matplotlib.use('TkAgg')
#       import matplotlib.pyplot as plt
#       plt.ion()
#   else: 
#       #print 'else'
#       import matplotlib
#       matplotlib.use('Agg')
#       import matplotlib.pyplot as plt
#       plt.ioff()

   # I initially wrote this backwards, convert x,ybin to make sense
   # Assumes a single frame in these bins
   xbin = 4096/xbpix
   ybin = 4096/ybpix
   #get the data. Read in as numpy array
   a = np.genfromtxt(matchfile)
   x = a[..., 0]
   y = a[..., 1]
   xresid = a[..., 6]
   yresid = a[..., 7]

   if verbose: print 'inital range: ', x.min(), x.max(), y.min(), y.max()

   #create empty arrays
   xr = np.empty(xbin*ybin)
   yr = np.empty(xbin*ybin)
   xedge = np.empty(xbin*ybin)
   yedge = np.empty(xbin*ybin)

   #start the binning. 
   xdiff = x.min()
   ydiff = y.min()
   counter = 0
   xstep = round((x.max()+abs(x.min()))/xbin)
   ystep = round((y.max()+abs(y.min()))/ybin)

   if verbose: print 'stepsize: ', xstep, ystep

   #bin things- this gets a little complicated, more than I would have liked...
   #should use a try catch for elements that only have 1 in bin... too lazy
   for i in range(xbin):
      for j in range(ybin):
         xedge[counter] = xresid[(x>xdiff) & (x<xdiff+xstep) & 
                               (y>ydiff) & (y<ydiff+ystep)].mean()
         yedge[counter] = yresid[(x>xdiff) & (x<xdiff+xstep) & 
                               (y>ydiff) & (y<ydiff+ystep)].mean()
        # if verbose: print xedge[counter],yedge[counter]
         xr[counter] = i
         yr[counter] = j
         counter+=1
         ydiff = ydiff+ystep
      xdiff = xdiff+xstep
      ydiff = y.min()
   if verbose: print xr.min(), xr.max(), yr.min(), yr.max()
   #find the range
   xr = xr*xstep-abs(x.min())#((x.max()+abs(x.min()))/xbin)
   yr = yr*ystep-abs(x.min())#((x.max()+abs(x.min()))/ybin)

   #debugging line
   if verbose: print 'range: ', xr.min(), xr.max(), yr.min(), yr.max(), xr.shape, yr.shape
   if verbose: print 'edge ranges:', xedge.min(), xedge.max(), yedge.min(), yedge.max()
   #help(xedge)
   

   #set up the plotting area
   plt.figure(figsize=(xsize, ysize), frameon=True)
   plt.axis([xr.min()*1.15, xr.max()*1.15, yr.min()*1.15, yr.max()*1.15])
   plt.subplots_adjust(left=.09, right=.98, top=.94, bottom=.05)
   plt.ylabel('Y (pix)')
   plt.xlabel('X (pix)')

   #make the plot
   #max arrow length
   if arrowlen==0:
      arrowlen = round((np.sqrt(xresid**2 + yresid**2).max())/2, 3) 
      if verbose:print 'using arrowlen of: '+str(arrowlen)

   Q = plt.quiver(xr, yr, xedge, yedge, scale=arrowlen/arwscale, angles='xy',
	        scale_units='xy') #make arrow plot
   plt.quiverkey(Q, .08, .01, arrowlen, str(arrowlen)+' pix (max)') #legend
   plt.suptitle(matchfile, size='large') #title
   plt.draw()
   if verbose: print 'range for quiver: ', xr.min(), xr.max(), yr.min(), yr.max()

   #figure out a good name for the file automaticly
   if (savename == '') & (save):
      directory = os.path.dirname(os.path.realpath(matchfile))+'/'
      #print directory
      #print matchfile
      if directory.find('notdd') > 0:
         ending = '_vector_notdd.png'
      elif directory.find('tdd') > 0:
         ending = '_vector_tdd.png'
      elif directory.find('orig') > 0:
         ending = '_vector_orig.png'
      else:
         ending = '_vector.png'

      #assumes _catalog_fit.match at end
      #savename = matchfile[0:matchfile.rfind('_',0,len(matchfile)-18)]+'.png'
      name = matchfile.rsplit('_')[-4].rsplit('/')[-1]+ending
      savename = directory+name

      if verbose: print 'savename is automatic: '+savename

   #write the file
#   if save: 
#      if os.path.isfile(savename):
#         os.remove(savename) 
# 
   print '  saving file: '+savename
   plt.savefig(savename)

   #decide to display or close
   if interactive: 
      plt.ion()
      plt.show()
   else: 
      plt.clf()
      plt.close()
      #matplotlib.use('TkAgg') #leave in a nice state


def rrplot(matchfile, xsize=10, ysize=10, forceMinMax=True, alpha=1,
        xrmax=0.45, xrmin=-0.45, yrmax=0.45, yrmin=-0.45, boundry=1.15):
   '''
   plot residuals vs residuals. Only one match file at a time.


   Returns:
   None


   Input:
   matchfile -  a matchfile to parse


   keywords:
   xsize - xsize of plot in inches. default: 10

   ysize - ysize of plot in inches. default: 6.75

   forceMinMax - Will force the min and maximum of the residual plot to be same
      in both X and Y. This is very convient for compairing the different
      pannels in the plot. default: True

   alpha - Transparency of the points in the plot. Very useful for trying to
      find multiple overlaping distrubutions. default: 1.0 (no transpenecncy)

   xrmax - maximum of X residial. default:0.45
   xrmin - mimimun of X residial. default:-0.45
   yrmax - maximum of Y residial. default:0.45
   yrmin - mimimum of Y residial. default:-0.45
   
   boundry - An extra padding factor to add to the edges of the plot. basically
      xresid.max()*boundry. Only applied if forceMinMax. default: 1.15
   '''
   import matplotlib.pyplot as plt

   a = np.genfromtxt(matchfile)
   xresid = a[..., 6]
   yresid = a[..., 7]


   #change the bounds if foceMinMax is false
   if not forceMinMax:
      xrmax = xresid.max()*boundry
      xrmin = xresid.min()*boundry
      yrmax = yresid.max()*boundry
      yrmin = yresid.min()*boundry

   plt.figure(figsize=(xsize, ysize), frameon=True)

   plt.axis([xrmin, xrmax, xrmin, xrmax])
   #plt.axis([xresid.min(), xresid.max(), yresid.min(), yresid.max()])
   plt.scatter(xresid, yresid, marker='.', alpha=alpha)

   plt.suptitle(matchfile, size='large')
   plt.ylabel('dY (pix)')
   plt.xlabel('dX (pix)')


def hist_rrplot(filename, savename):
    ''' plot x, y residuals with histograms

    This doesnt work with match files yet. just Vera's resids files. 
    sould be an easy change
    '''

    table = ascii.read(filename)

    xresid = table['col8'].data
    yresid = table['col9'].data

    nullfmt = NullFormatter()         # no labels

    # definitions for the axes
    left, width = 0.1, 0.65
    bottom, height = 0.1, 0.65
    bottom_h = left_h = left + width + 0.01

    rect_scatter = [left, bottom, width, height]
    rect_histx = [left, bottom_h, width, 0.16]
    rect_histy = [left_h, bottom, 0.16, height]

    # start the plotting
    plt.ion()
    plt.figure(1, figsize=(8, 8))

    title = filename.split('/')[-1]
    plt.suptitle(title, size='large')

    axScatter = plt.axes(rect_scatter)
    axScatter.set_xlabel('X residual (pix)')
    axScatter.set_ylabel('Y residual (pix)')
    axHistx = plt.axes(rect_histx)
    axHisty = plt.axes(rect_histy)

    axHistx.xaxis.set_major_formatter(nullfmt)
    axHisty.yaxis.set_major_formatter(nullfmt)

    axScatter.scatter(xresid, yresid, rasterized=False, alpha=.1)

    # now determine nice limits by hand:
    binwidth = 0.005
    xymax = np.max([np.max(np.fabs(xresid)), np.max(np.fabs(yresid))])
    lim = (int(xymax / binwidth) + 1) * binwidth

    axScatter.set_xlim((-lim, lim))
    axScatter.set_ylim((-lim, lim))

    bins = np.arange(-lim, lim + binwidth, binwidth)
    axHistx.hist(xresid, bins=bins, rasterized=False)
    axHisty.hist(yresid, bins=bins, orientation='horizontal', rasterized=False)

    axHistx.set_xlim(axScatter.get_xlim())
    axHisty.set_ylim(axScatter.get_ylim())

    plt.show()
    plt.savefig(savename, dpi=300)


def hdr_info(searchPattern, reverse=True):
   '''
   print info on images matching the search pattern.
   will print filename,filter,date-obs,ra,dec,pa_v3,postarg1,postarg2
   This is a little messed up and was an early attempt at trying lamda
   functions.
   '''
   matches=glob.glob(searchPattern)

   if len(matches) ==0: print 'No matches found for '+searchPattern
   else:
      date=[]
      filter1=[]
      filter2=[]
      ra_targ=[]
      dec_targ=[]
      pa_v3=[]
      postarg1=[]
      postarg2=[]
      reports = []
      print '       file              filter         date-obs   ra_targ   dec_targ   pa_v3   postarg 1  postarg 2   propid' 

      for match in matches:
         #should probably use getval here 
         hdr=fits.getheader(match)
         name=match.rsplit('/')[-1]

         date = dec_year(hdr['DATE-OBS'])
         filter1 = hdr['FILTER1']
         filter2 = hdr['FILTER2']
         ra_targ = hdr['RA_TARG']
         dec_targ = hdr['DEC_TARG']
         pa_v3 = hdr['PA_V3']
         postarg1 = hdr['POSTARG1']
         postarg2 = hdr['POSTARG2']
         propid = hdr['PROPOSID']

         reports.append(report(name, date, filter1, filter2, ra_targ, dec_targ, pa_v3, postarg1, postarg2, propid))
   
      reports = sorted(reports, key=lambda report:report.date, reverse=reverse)

      for r in reports:
          r.print_report()
          #r.print_prop()


class report:
    '''
    class for the header info function.
    Gather information on an image to print so that it can be sorted using
    lamda functions
    '''
    def __init__(self, name, date, filter1, filter2, pa_v3 , ra_targ, dec_targ, postarg1, postarg2, propid):
        self.name = name
        self.date = date
        self.filter1 = filter1
        self.filter2 = filter2
        self.ra_targ = ra_targ
        self.dec_targ = dec_targ
        self.pa_v3 = pa_v3
        self.postarg1 = postarg1
        self.postarg2 = postarg2
        self.propid = propid

    def __repr__(self):
        return repr((self.name, self.date, self.filter1, self.filter2, self.ra_targ, self.dec_targ, self.pa_v3, self.postarg1, self.postarg2, propid))

    def print_report(self):
        #  change
        print '%19s %7s  %7s  %10s   %-4.5f  %-4.5f  %-4.6f   %-4.6f  %-4.6f   %6d' % (self.name, self.filter1, self.filter2, self.date, self.pa_v3, self.ra_targ, self.dec_targ, self.postarg1, self.postarg1, self.propid)

    def print_prop(self):
        print '%19s  %7d' % (self.name, self.propid)


def dec_year(date, verbose=False):
    '''
    Returns decimil year of an obs-date string. Not the most accurate, but close
    enough for what I need.
    Uses: year + ((month - 1) / 12.0) + ((day / 30.0) / 12.0)
    '''
    year = float(date[0:4])
    month = float(date[5:7])
    day = float(date[8:10])

    if verbose:
        print 'Year: ', year
        print 'month: ', month
        print 'day: ', day
    
    # starts at month 1 = january, not 0
    decyear = year + ((month - 1) / 12.0) + ((day / 30.0) / 12.0)
    return round(decyear, 3)


def updateref(searchpattern, verbose=True, small_path=True):
    '''
    update the reference file to point to the location of the new reference
    file for certain images. decides if before or after SM4 and updates
    the header with the correct IDCTAB, D2IMFILE and NPOLFILE. Only works
    for ACS/WFC!!
    '''
    files = glob.glob(searchpattern)

    if verbose:
        print 'files found:'
        print files

    if small_path:
        dire = 'donedist$'
    else:
        dire = '/user/dborncamp/distortion/deliver/'

    d2imfile = dire + 'wfc_update3_d2im.fits'  # d2imfile does not change with filt
#    d2imfile = '/grp/hst/acs3/verap/DISTORTION/DD_NPOLs/acs_230115_d2im.fits'

    for fil in files:
        print '\nworking ' + fil
        with fits.open(fil, mode='update') as temp:
            header = temp[0].header  # get the first header

            obs_date = header['DATE-OBS']
            filter1 = header['filter1']
            filter2 = header['filter2']

            date = dec_year(obs_date)

            if date < 2008:
                idcfile = dire + 'wfc_update3_pre_idc.fits'
#                idcfile = '/grp/hst/acs/dborncamp/pre_sm04/all/061915_pre_all_idc.fits'
            else:
                idcfile = dire + '012017_post_every_idc.fits'
#                idcfile = '/grp/hst/acs/dborncamp/post_sm04/all/061915_post_all_idc.fits'

            npolfile = dire + 'wfc_adriz2.0_' + filter1 + '_' + filter2 + '_npl.fits'
            npolfile = dire + 'wfc_update3_' + filter1 + '_' + filter2 + '_npl.fits'

#            print 'Change NPOLFILE!!\n'

            if verbose:
                print '\nchosen files for ' + fil
                print '  idcfile: ' + idcfile
                print '  npolfile: ' + npolfile
                print '  d2imfile: ' + d2imfile
                print '  date: ', date

            print 'changing header for ' + fil
            header['IDCTAB'] = idcfile
            header['NPOLFILE'] = npolfile
            header['D2IMFILE'] = d2imfile
