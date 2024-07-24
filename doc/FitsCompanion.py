import matplotlib.pyplot as plt
from matplotlib.colors import Normalize, LogNorm, SymLogNorm

import numpy as np

from astropy.io import fits
from astropy.wcs import WCS
from astropy.convolution import convolve, Gaussian2DKernel
from astropy.coordinates import Angle, SkyCoord
from astropy import units as u
from astropy.nddata import Cutout2D
from astropy.table import Table

import scienceplots
plt.style.use(['science','ieee'])

from regions import Region, PixelRegion, SkyRegion, TextSkyRegion, TextPixelRegion


def plot_side_by_side(pc1, pc2, norm='lin', vmin=0, vmax=1, dpi=480, compress=False, grid=True, axis_label=True, cbar=True, savefig=False, axislabel_size=10, tick_label_size=9, cbar_labelsize=9, axis_ticks=True, figsize=(5, 3)):
    """
    Plot two PrimCompanion objects side by side with a shared y-axis and a common x-axis label.

    Parameters:
    - pc1, pc2 (PrimCompanion): PrimCompanion objects to plot.
    - norm (str): Normalization method for the image data. Accepted values are 'linear' or 'lin' for linear normalization, 'log' for logarithmic normalization, and 'log2' for symmetric logarithmic normalization.
    - vmin (float): Minimum value for the color scale.
    - vmax (float): Maximum value for the color scale.
    - dpi (int, optional): Dots per inch of the figure. Default is 480.
    - compress (bool, optional): If True, compress the image by plotting only every n-th pixel. Default is False.
    - grid (bool, optional): If True, display a grid on the plot. Default is True.
    - axis_label (bool, optional): If True, display axis labels. Default is True.
    - cbar (bool, optional): If True, display color bar. Default is True.
    - savefig (str or bool, optional): If a string is provided, save the figure to the specified path. Default is False.
    - axislabel_size (int, optional): Size of the axis labels. Default is 10.
    - tick_label_size (int, optional): Size of the tick labels. Default is 9.
    - cbar_labelsize (int, optional): Size of the color bar labels. Default is 9.
    - axis_ticks (bool, optional): If True, display axis ticks. Default is True.
    - figsize (tuple, optional): Size of the figure. Default is (10, 5).

    Returns:
    - fig (matplotlib.figure.Figure): The generated figure.
    - axes (list of matplotlib.axes.Axes): The axes objects.
    """
    if compress:
        n = 10
        data1 = pc1.data[::n, ::n]
        wcs1 = pc1.wcs[::n, ::n]
        data2 = pc2.data[::n, ::n]
        wcs2 = pc2.wcs[::n, ::n]
    else:
        data1 = pc1.data
        wcs1 = pc1.wcs
        data2 = pc2.data
        wcs2 = pc2.wcs

    if norm in ['linear', 'lin']:
        norm = Normalize(vmin=vmin, vmax=vmax, clip=True)
    elif norm in ['log', 'log10']:
        norm = LogNorm(vmin=vmin, vmax=vmax, clip=True)
    elif norm == 'log2':
        norm = SymLogNorm(linthresh=vmin, vmin=vmin, vmax=vmax, clip=True, base=2)
    else:
        raise ValueError('Invalid normalization method.')

    fig, axes = plt.subplots(1, 2, dpi=dpi, figsize=figsize, subplot_kw={'projection': wcs1}, sharey=True, layout='constrained')

    im1 = axes[0].imshow(data1, cmap='magma', norm=norm, origin='lower', aspect='equal')
    im2 = axes[1].imshow(data2, cmap='magma', norm=norm, origin='lower', aspect='equal')

    # Configure axes
    for i, ax in enumerate(axes):
        ra, dec = ax.coords[0], ax.coords[1]
        ra.set_axislabel(" ")
        dec.set_axislabel(" ")

        if axis_ticks:
            ra.tick_params(direction='in', color='lightgrey')
            dec.tick_params(direction='in', color='lightgrey')

            ra.display_minor_ticks(True)
            dec.display_minor_ticks(True)

            ra.set_ticklabel(size=tick_label_size)
            if i == 0:
                dec.set_ticklabel(size=tick_label_size)
            else:
                dec.set_ticklabel_visible(False)

        if axis_label and i == 0:
            dec.set_axislabel('Declination', size=axislabel_size, minpad=.7)
        if grid:
            ax.grid(alpha=.3, color='white', linestyle='dotted')

    if axis_label:
        fig.supxlabel('Right Ascension', size=axislabel_size, y=0.001, x=.45)

    if cbar:
        cbar = fig.colorbar(im1, ax=axes, orientation='vertical', fraction=0.02468, pad=0.01)
        cbar.ax.tick_params(which='both', labelsize=cbar_labelsize, color='lightgrey')

    if savefig:
        fig.savefig(savefig, dpi=fig.dpi, figsize=figsize, layout='constrained') # WTF 

    return fig, axes


# WIP
class MyHDUList(fits.HDUList):
    '''
    WORK IN PROGRESS
    '''
    def __init__(self, file_path=None, hdul=None):
        if file_path:
            self.file_path = file_path
            with fits.open(self.file_path) as hdul:
                hdul.verify('fix')
                self._hdul = hdul
        elif hdul:
            self.file_path = None
            self._hdul = hdul
        else:
            raise ValueError("Either file_path or hdul must be provided.")


class BinCompanion(fits.BinTableHDU):
    def __init__(self, data=None, header=None, **kwargs):
        super().__init__(data=data, header=header)
        self.data = self.data
        self.header = self.header
        self.table_data = Table(self.data)


    def from_fits(self, file_path, index=1):
        """
        Initialize the BinCompanion object from a FITS file.

        Parameters:
        - file_path (str): Path to the FITS file.
        """
        if not isinstance(file_path, str):
            raise TypeError("file_path must be a string.")
        
        with fits.open(file_path) as hdul:
            hdul.verify('fix')
            self.data = hdul[index].data
            self.table_data = Table(self.data)
            self.header = hdul[index].header

        return self

    def hist(self, data_column, bins='auto', fill=True, dpi=300, **kwargs):
        counts, bins = np.histogram(data_column, bins=bins, **kwargs)

        fig, ax = plt.subplots(dpi=dpi, figsize=(8,8))

        ax.stairs(counts, bins, fill=True)

        return fig, ax


class PrimCompanion(fits.PrimaryHDU):
    """
    Extension of fits.PrimaryHDU with additional functionality.

    Parameters:
    - file_path (str, optional): Path to the FITS file. If provided, data and header will be loaded from the file. Default is None.
    - data (numpy.ndarray, optional): Data array. Default is None.
    - header (astropy.io.fits.Header, optional): Header object. Default is None.

    Attributes:
    - data (numpy.ndarray): Data array.
    - header (astropy.io.fits.Header): Header object.
    - wcs (astropy.wcs.WCS): World Coordinate System object.

    Methods:
    - fgauss(sigma, inplace=False): Apply a Gaussian filter to the data.
    - cutout(position, size, inplace=False): Create a cutout of the data.
    - plot(norm='lin', vmin=0, vmax=1, dpi=800, compress=False, grid=True, label=True, cbar=True): Create a plot of the data.

    """
    def __init__(self, data=None, header=None, **kwargs):
        """
        Initialize the PrimCompanion object.

        Parameters:
        - data (numpy.ndarray, optional): Data array. Default is None.
        - header (astropy.io.fits.Header, optional): Header object. Default is None.
        """
        super().__init__(data=data, header=header)
        self.data = self.data
        self.header = self.header
        self._wcs = WCS(self.header, relax=True)
        self._regions = kwargs.get('regions', {})

        if not isinstance(self._regions, dict):
            raise TypeError("regions must be a dictionary with labels as keys and regions as values.")

    @property
    def wcs(self):
        """
        Return the World Coordinate System (WCS) object.

        Returns:
        - wcs (astropy.wcs.WCS): World Coordinate System object.
        """
        return self._wcs
    
    @property
    def regions(self):
        """
        Get the regions associated with the image.

        Returns:
        list: A list of regions.Region or list of regions.PixelRegion instances.
        """
        return self._regions

    def _update_wcs(self):
        """
        Update the WCS object based on the header.
        """
        self._wcs = WCS(self.header, relax=True)

    def from_fits(self, file_path):
        """
        Load data and header from a FITS file.

        Parameters:
        - file_path (str): The path to the FITS file.

        Returns:
        None

        This method opens the FITS file specified by `file_path`, verifies the file,
        and updates the data and header attributes of the PrimCompanion object.
        It also calls the `_update_wcs` method to update the World Coordinate System (WCS) object.
        """
        if not isinstance(file_path, str):
            raise TypeError("file_path must be a string.")
        
        with fits.open(file_path) as hdul:
            hdul.verify('fix')
            self.data = hdul[0].data
            self.header = hdul[0].header
            self._update_wcs()

        return self

    def fgauss(self, sigma, inplace=False):
        """
        Apply a Gaussian filter to the data.

        Parameters:
        - sigma (float): Standard deviation of the Gaussian kernel.
        - inplace (bool, optional): If True, apply the filter in place. Default is False.

        Returns:
        - PrimCompanion: A new PrimCompanion object with the filtered data if inplace is False, self otherwise.
        """
        if not isinstance(sigma, (int, float)):
            raise TypeError("sigma must be a float or int.")
        if not isinstance(inplace, bool):
            raise TypeError("inplace must be a boolean.")

        gaussian_kernel = Gaussian2DKernel(sigma)
        convolved_data = convolve(self.data, gaussian_kernel)
        if inplace:
            self.data = convolved_data
            return self
        else:
            return PrimCompanion(data=convolved_data, header=self.header, regions=self._regions)
        
    def cutout(self, position, size, inplace=False):
        """
        Create a cutout of the data.

        Parameters:
        - position (tuple): (x, y) position of the center of the cutout. Can be SkyCoord or tuple of coordinates.
        - size (tuple): (width, height) size of the cutout. Can be Quantity or tuple of coordinates.
        - inplace (bool, optional): If True, modify the data and header in place. Default is False.

        Returns:
        - PrimCompanion: A new PrimCompanion object with the cutout data if inplace is False, None otherwise.
        """
        cut_array = Cutout2D(self.data, position, size, wcs=self._wcs)
        cut_header = cut_array.wcs.to_header()
        if inplace:
            self.data = cut_array.data
            self.header = cut_header
            self._update_wcs()

            return self
        
        else:
            return PrimCompanion(data=cut_array.data, header=cut_header, regions=self._regions)


    def add_region(self, region, label):
        """
        Add a region or a list of regions to the regions dictionary with a label.

        Parameters:
        - region (regions.Region or list of regions.Region): The region or list of regions to add.
        - label (str or list of str): The label or list of labels corresponding to the regions.

        Returns:
        None

        Raises:
        - TypeError: If the provided object is not a regions.Region instance or a list of regions.Region instances.
        """
        if isinstance(region, Region):
            if label is None:
                raise ValueError("A label must be provided for the region.")
            if not isinstance(label, str):
                raise TypeError("label must be a string.")
            
            self._regions[label] = region
            
        elif isinstance(region, list):
            if not isinstance(label, list) or len(label) != len(region):
                raise ValueError("A list of labels of the same length as the list of regions must be provided.")
            if not all(isinstance(l, str) for l in label):
                raise TypeError("All items in the label list must be strings.")
            if all(isinstance(r, Region) for r in region):
                self._regions.update(dict(zip(label, region)))
            else:
                raise TypeError("All items in the region list must be instances of regions.Region")
        else:
            raise TypeError("The object to add must be an instance of regions. Region or a list of regions.Region instances")
        
        return self
    
    def remove_region(self, label):
        """
        Remove a region by its label.

        Parameters:
        - label (str): The label of the region to remove.

        Returns:
        None

        Raises:
        - KeyError: If the label does not exist in the regions dictionary.
        """
        try:
            del self.regions[label]
        except KeyError:
            raise KeyError(f"Region with label '{label}' does not exist.")
        
        return self

    def clear_regions(self):
        """
        Clear all regions.

        Returns:
        None
        """
        self.regions.clear()
        return self

    def get_region(self, label):
        """
        Retrieve a region by its label.

        Parameters:
        - label (str): The label of the region to retrieve.

        Returns:
        - region (regions.Region): The region associated with the label.

        Raises:
        - KeyError: If the label does not exist in the regions dictionary.
        """
        try:
            return self.regions[label]
        except KeyError:
            raise KeyError(f"Region with label '{label}' does not exist.")

    def list_regions(self):
        """
        List all region labels.

        Returns:
        - labels (list of str): A list of all region labels.
        """
        return list(self.regions.keys())

    
    def plot(self, norm='lin', vmin=0, vmax=1, dpi=480, compress=False, grid=True, axis_label=True, cbar=True, regions=True, savefig=False, axislabel_size=10, tick_label_size=9, cbar_labelsize=9, axis_ticks=True, figsize=(5,3)):
        """
        Create a plot of the data.

        Parameters:
        - norm (str): Normalization method for the image data. Accepted values are 'linear' or 'lin' for linear normalization, and 'log' for logarithmic normalization.
        - vmin (float): Minimum value for the color scale.
        - vmax (float): Maximum value for the color scale.
        - dpi (int, optional): Dots per inch of the figure. Default is 300.
        - compress (bool, optional): If True, compress the image by plotting only every n-th pixel. Default is False.
        - grid (bool, optional): If True, display a grid on the plot. Default is True.
        - label (bool, optional): If True, display axis labels. Default is True.
        - cbar (bool, optional): If True, display color bar. Default is True.

        Returns:
        - fig (matplotlib.figure.Figure): The generated figure.
        - ax (matplotlib.axes.Axes): The axes object.
        """
        if compress:
            n = 10
            image_data = self.data[::n, ::n]
            wcs = self._wcs[::n, ::n]
        else:
            image_data = self.data
            wcs = self._wcs

        if norm in ['linear', 'lin']:
            norm = Normalize(vmin=vmin, vmax=vmax, clip=True)
        elif norm in ['log', 'log10']:
            norm = LogNorm(vmin=vmin, vmax=vmax, clip=True)
        elif norm == 'log2':
            norm = SymLogNorm(linthresh=vmin, vmin=vmin, vmax=vmax, clip=True, base=2)
        else:
            raise ValueError('Invalid normalization method.')

        fig = plt.figure(dpi=dpi, tight_layout=True, figsize=figsize)
        ax = fig.add_subplot(111, projection=wcs)
        im = ax.imshow(image_data, cmap='magma', norm=norm, origin='lower', aspect='equal')

        ra, dec = ax.coords[0], ax.coords[1]
        ra.set_axislabel(" ")
        dec.set_axislabel(" ")
        
        # ra.set_format_unit('degree')
        if axis_ticks:
            ra.tick_params(direction='in', color='lightgrey')
            dec.tick_params(direction='in', color='lightgrey')

            ra.display_minor_ticks(True)
            dec.display_minor_ticks(True)

            ra.set_ticklabel(size=tick_label_size)
            dec.set_ticklabel(size=tick_label_size)

        if axis_label:
            ra.set_axislabel('Right ascension', size=axislabel_size, minpad=.7)
            dec.set_axislabel('Declination', size=axislabel_size, minpad=.6)
        
            if grid:
                ax.grid(alpha=.3, color='white', linestyle='dotted')
        else:
            ax.axis('off')

        if cbar:
            fig_cbar = fig.colorbar(im, ax=ax, pad=0.01)
            fig_cbar.ax.tick_params(which='both', labelsize=cbar_labelsize, color='lightgrey')
            if norm == 'lin':
                fig_cbar.formatter.set_powerlimits((0, 0))

        if regions:
            if isinstance(regions, list):
                plot_regions = {label: self.regions[label] for label in regions if label in self.regions}
            else:
                plot_regions = self.regions

            for label, region in plot_regions.items():

                if isinstance(region, PixelRegion):
                    pixel_region = region
                elif isinstance(region, SkyRegion):
                    pixel_region = region.to_pixel(self._wcs)

                if hasattr(pixel_region, 'text'):
                    pixel_region.plot(ax=ax, color='white')
                else:
                    pixel_region.plot(ax=ax, edgecolor='white', linewidth=1, linestyle='dotted')

        if savefig:
            fig.savefig(savefig, dpi=dpi, figsize=figsize)

        return fig, ax

    
    



    


