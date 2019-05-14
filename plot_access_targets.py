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
fig, ax = plt.subplots(figsize=(6.5, 3))
ax.set_title('ACCESS Targets')
ax.set_xlabel('Equlibrium Temperature (K)')
ax.set_ylabel('Planetary Radius ($R_{Jup}$)')

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
ax.legend(loc='upper left')

plt.savefig('access_targets.pdf', bbox_inches='tight')
