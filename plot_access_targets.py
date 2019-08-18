import astropy.units as u
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

################################################################################
# Functions
def calc_T_eq(T_star, R_star, distance, albedo):
    """
    Calculate the equilibrium temperature of a planet
    with a given albedo at a given distance from a star
    Inputs:
        T_star   : effective temperature of star in K
        R_star   : radius of star in solar units
        distance : orbital distance in AU
    """

    # convert to km
    R_star = R_star.to(u.km)
    distance = distance.to(u.km)

    T_eq = T_star * (1 - albedo)**(0.25) * (R_star / (2*distance))**(0.5)
    return T_eq

################################################################################
# Load exoplanet.eu catalog
df = pd.read_csv('exoplanet.eu_catalog.csv')
df.columns = df.columns.str.strip('# ')
df = df.rename(columns={'name': 'planet_name'})

# Only consider transiting exoplanets
df = df[df.detection_type == 'Primary Transit']

# Calculate equilibrium temperatures
df['eq_temp'] = calc_T_eq(df.star_teff.values*u.K, df.star_radius.values*u.R_sun,
                          df.semi_major_axis.values*u.AU, 0.1)

# Load ACCCESS targets
df2 = pd.read_csv('targets.csv')

################################################################################
# Make figure
fig, ax = plt.subplots(figsize=(25, 15))
ax.set_title('ACCESS Targets')
ax.set_xlabel('Equlibrium Temperature (K)')
ax.set_ylabel('Planetary Radius ($R_{Jup}$)')

# transition temperatures between important molecules in exoplanet atmospheres. Gotten from Ben's 2016 ACCESS poster
H2O = 300
NH3_N2 = 600
CH4_CO = 1000
MnS = 1300
Silicates_MetalOxides = [1600,1900]
ax.axvline(x = H2O, ls = '--', color ='k', alpha=0.5)
ax.text(H2O-35, 1.3, '$H_2O$')
ax.axvline(x = NH3_N2, ls = '--', color ='k', alpha=0.5)
ax.text(NH3_N2-70, 1.5, '$NH_3 -> N_2$')
ax.axvline(x = CH4_CO, ls = '--', color ='k', alpha=0.5)
ax.text(CH4_CO-70, 1.6, '$CH_4 -> CO$')
ax.axvline(x = MnS, ls = '--', color ='k', alpha=0.5)
ax.text(MnS-30, 1.75, 'MnS')
ax.axvspan(Silicates_MetalOxides[0], Silicates_MetalOxides[1], alpha=0.25, color='k')
ax.text(np.mean(Silicates_MetalOxides)-150, .6, 'Silicates/Metal-oxides')

# Plot all exoplanets
ax.plot(df.eq_temp, df.radius,
        ls='', marker='o', mec='lightgray', mfc='None', ms=4, label='')

# Plot our targets
for name in df2.planet_name[df2.future==1]:
    target = df[df.planet_name==name]
    ax.plot(target.eq_temp, target.radius,
            ls='', marker='o', mec='k', mfc='gray', ms=10, label='')
for name in df2.planet_name[df2.obs_complete==1]:
    target = df[df.planet_name==name]
    ax.plot(target.eq_temp, target.radius,
            ls='', marker='o', mec='k', mfc='C1', ms=10, label='')
for name in df2.planet_name[df2.in_prep==1]:
    target = df[df.planet_name==name]
    ax.plot(target.eq_temp, target.radius,
            ls='', marker='o', mec='k', mfc='C0', ms=10, label='')
for name in df2.planet_name[df2.published==1]:
    target = df[df.planet_name==name]
    ax.plot(target.eq_temp, target.radius,
            ls='', marker='o', mec='k', mfc='C2', ms=10, label='')

# Hack a legend
ax.plot([], [], ls='', marker='o', mec='k', mfc='C2', ms=10, label='Published')
ax.plot([], [], ls='', marker='o', mec='k', mfc='C0', ms=10, label='Paper in Prep.')
ax.plot([], [], ls='', marker='o', mec='k', mfc='C1', ms=10, label='Analysis Underway')
ax.plot([], [], ls='', marker='o', mec='k', mfc='gray', ms=10, label='Collecting Data')
ax.plot([], [], ls='--', color='k', ms=4, label='Temp. transition of molecules', alpha=0.5)
ax.legend(loc='upper left')

plt.savefig('access_targets.pdf', bbox_inches='tight')
