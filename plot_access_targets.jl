### A Pluto.jl notebook ###
# v0.16.1

using Markdown
using InteractiveUtils

# ╔═╡ fa6c24e0-2dc8-11ec-198e-0318e4603d37
begin
	import Pkg
	Pkg.activate(Base.current_project())
	
	# Plotting
	using AlgebraOfGraphics, CairoMakie
	set_aog_theme!()
	
	# Tables
	using Chain, CategoricalArrays, CSV, DataFrames, DataFrameMacros, NaturalSort
	
	# Web client/server
	using HTTP
	
	# Widgets, table of contents, other goodies
	using PlutoUI
end

# ╔═╡ 8ec24605-3e97-43ef-9dcc-989aed13bb96
md"""
# Survey plot

In this notebook we will pull down data of known transiting exoplanets and place our ACCESS targets in this context.

$(TableOfContents(title = "📖 Contents"))
"""

# ╔═╡ 1258eb09-0413-4e53-b1b2-4025de59c9cf
md"""
## 📦 Download data

First we query the NASA Exoplanet Archive [TAP API](https://exoplanetarchive.ipac.caltech.edu/docs/TAP/usingTAP.html) to get the most up to date list of ground and space-based observations of transiting exoplanets:
"""

# ╔═╡ 70d30677-883c-42eb-b894-5991289039b6
df_all = let
		columns = [
		"pl_name",
		"disc_facility",
		"tic_id",
		"pl_radj",
		"pl_bmassj",
		"pl_eqt",
		"st_rad",
		"sy_jmag",
	]
	url = "https://exoplanetarchive.ipac.caltech.edu/TAP"
	#cond = "tran_flag+=1+and+pl_eqt+<+1000+and+pl_rade+<+4"
	cond = "tran_flag+=1"
	query = "select+$(join(columns, ','))+from+pscomppars+where+$(cond)&format=csv"
	request = HTTP.get("$(url)/sync?query=$(query)")
	CSV.read(request.body, DataFrame)
end

# ╔═╡ 307c3e44-f66a-4134-9ac8-300edea176f4
md"""
There are currently **$(nrow(df_all))** targets found. Let's clean up the above table by dropping targets with missing column values:
"""

# ╔═╡ 9a2ec7d8-b0b1-4a91-8cf9-94bf19b95406
df = dropmissing(df_all, [:pl_radj, :pl_eqt, :pl_bmassj, :st_rad, :sy_jmag])

# ╔═╡ a88bdd58-e048-4f45-86c6-7df202e05169
md"""
Cool, we now have **$(nrow(df))** targets remaining.
"""

# ╔═╡ 86a2aa66-442b-415e-91d5-38084850fb1d
md"""
## 🇨🇱 ACCESS targets

Next we load in our list of ACCESS targets, which can also be viewed directly in the repo:

!!! todo

	Add link to targets.csv
"""

# ╔═╡ b8db618a-411b-4642-996e-97ac1ba5fd13
df_ACCESS_status = CSV.read("targets.csv", DataFrame)

# ╔═╡ 1d4fdd0d-4bea-4909-822e-231f4afa1bcf
md"""
Now let's merge the archive data into our ACCESS table to make plotting everything more convenient, and split out each category, which we label as `status`:
"""

# ╔═╡ 7455d1cf-cd40-4ebd-8517-ca534e6c37de
begin
	cats = ["Published", "In prep.", "Analysis underway", "Collecting data"];
	cv = categorical(cats; levels=cats)
end

# ╔═╡ e27aba11-58a1-487b-8715-32b5e0b749b9
md"""
!!! note
	We use `CategoricalArrays.jl` to encode each category in a more memory efficient format than regular `Strings`
"""

# ╔═╡ efcef650-78df-40b7-97a1-93c26ac007be
function status(published, in_prep, obs_complete)
	if published == 1
		return cv[1]
	elseif in_prep == 1
		return cv[2]
	elseif in_prep == 0 && published == 0 && obs_complete == 1
		return cv[3]
	else
		return cv[4]
	end
end

# ╔═╡ 3d7acddc-2033-4c4a-90dc-df9378403301
df_ACCESS = @chain df begin
	@subset :pl_name ∈ df_ACCESS_status.planet_name
	leftjoin(df_ACCESS_status, _, on=:planet_name => :pl_name)
	# Add `status` column
	@transform :status = status(:published, :in_prep, :obs_complete)
	sort(:planet_name, lt=natural)
end

# ╔═╡ d62c8f1d-3cc3-4ad4-a42a-e957194c40b1
md"""
Looks good!
"""

# ╔═╡ 77b9a47d-6e6e-4d11-8188-c76bbb6dd772
md"""
## 🖌️ Plot

With all of the data now loaded, we create our plot:
"""

# ╔═╡ 88248c35-63e0-41a5-9f78-4da6f6e1da9f
md"""
This plot was made using `AlgebraOfGraphics.jl`, an [inventive take](http://juliaplots.org/AlgebraOfGraphics.jl/dev/philosophy/) on analyzing and visualizing tabular data by "factoring out" common tasks.

!!! note
	For comparison, here are the commands that would produce a similar plot in vanilla `Makie.jl`, the plotting library that powers the `AlgrebraOfGraphics.jl` framework:

	```julia
		fig = Figure()
		ax = Axis(fig[1, 1];
			xlabel = "Equilibrium temperature (K)",
			ylabel = "Planetary Radius (Rⱼ)",
			limits = ((0.0, 3_000.0), (0.0, 2.2)),
		)

		# All targets
		scatter!(ax, df.pl_eqt, df.pl_radj, marker='○', color=(:darkgrey))

		# ACCESS targets
		gdf = groupby(df_ACCESS, :status)
		for (k, df) ∈ pairs(gdf)
			scatter!(ax, df.pl_eqt, df.pl_radj, markersize=25, label=string(k.status))
		end

		Legend(fig[1, 2], ax, "Status")

		fig
	```

	A lot of nice things like automatic legend placement and grouping are already done for us in `AlgebraOfGraphics.jl`. Repetitively accessing `pl_eqt` and `pl_radj` was also able to be nicely factored out, leading to terser, more maintable and extensible code.
"""

# ╔═╡ c88dd755-0dfa-43b0-baef-83212fd3be70
md"""
## Notebook setup
"""

# ╔═╡ 3d210896-5787-481e-9b8c-95318225e676
COLORS = Makie.wong_colors()

# ╔═╡ b74e9dce-cdc2-42c8-bed8-d855b642d312
let
	m = mapping(
		:pl_eqt => "Equilibrium temperature (K)",
		:pl_radj => "Planetary Radius (Rⱼ)",
	)
	marker = visual(marker='○', color=(:darkgrey))
	m_ACCESS = mapping(color = :status => "Status")
	
	# Plot all targets and ACCESS targets
	plt = m * (data(df)*marker + data(df_ACCESS)*m_ACCESS*visual(markersize=25))
	draw(plt;
		axis = (limits=(limits = ((0.0, 3_000.0), (0.0, 2.2))),),
		palettes = (color=[COLORS[3], COLORS[1], COLORS[2], :grey],),
	)
end

# ╔═╡ 9f5c0153-68ec-4ca1-a8e4-527a2267ab73
html"""
<style>
#launch_binder {
	display: none;
}
body.disable_ui main {
		max-width : 95%;
	}
@media screen and (min-width: 1081px) {
	body.disable_ui main {
		margin-left : 10px;
		max-width : 72%;
		align-self: flex-start;
	}
}
</style>
"""

# ╔═╡ Cell order:
# ╟─8ec24605-3e97-43ef-9dcc-989aed13bb96
# ╟─1258eb09-0413-4e53-b1b2-4025de59c9cf
# ╟─307c3e44-f66a-4134-9ac8-300edea176f4
# ╠═70d30677-883c-42eb-b894-5991289039b6
# ╠═9a2ec7d8-b0b1-4a91-8cf9-94bf19b95406
# ╟─a88bdd58-e048-4f45-86c6-7df202e05169
# ╟─86a2aa66-442b-415e-91d5-38084850fb1d
# ╠═b8db618a-411b-4642-996e-97ac1ba5fd13
# ╟─1d4fdd0d-4bea-4909-822e-231f4afa1bcf
# ╠═7455d1cf-cd40-4ebd-8517-ca534e6c37de
# ╟─e27aba11-58a1-487b-8715-32b5e0b749b9
# ╠═3d7acddc-2033-4c4a-90dc-df9378403301
# ╠═efcef650-78df-40b7-97a1-93c26ac007be
# ╟─d62c8f1d-3cc3-4ad4-a42a-e957194c40b1
# ╟─77b9a47d-6e6e-4d11-8188-c76bbb6dd772
# ╠═b74e9dce-cdc2-42c8-bed8-d855b642d312
# ╟─88248c35-63e0-41a5-9f78-4da6f6e1da9f
# ╟─c88dd755-0dfa-43b0-baef-83212fd3be70
# ╠═3d210896-5787-481e-9b8c-95318225e676
# ╠═fa6c24e0-2dc8-11ec-198e-0318e4603d37
# ╟─9f5c0153-68ec-4ca1-a8e4-527a2267ab73
