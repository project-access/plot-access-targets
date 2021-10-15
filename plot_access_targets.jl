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
Now let's merge the archive data into our ACCESS table to make plotting everything more convenient, and split out each category:
"""

# ╔═╡ 936682e4-3e71-4af2-9d72-b419e629858b
cats = ["Published", "In prep.", "Analysis underway", "Collecting data"]

# ╔═╡ 71e7dad5-2812-439d-bc14-17da539b1484
cv = categorical(cats)

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
	@transform :status = status(:published, :in_prep, :obs_complete)
	sort(:planet_name, lt=natural)
end

# ╔═╡ 0d81d22e-cead-4a21-93f7-ba07c3ede24c
df_ACCESS_published = @subset df_ACCESS :published == 1

# ╔═╡ 28fb4a1e-7b6b-4bc2-b27b-f91248ad8a51
df_ACCESS_in_prep = @subset df_ACCESS :in_prep == 1

# ╔═╡ 275bb8ea-5c4f-4782-9c6e-9d253f6f87ed
df_ACCESS_underway = @subset df_ACCESS let
	:in_prep == 0 && :published == 0 && :obs_complete == 1
end

# ╔═╡ 0064cd4d-dfa1-4f07-afc6-387b8d83e5bf
df_ACCESS_collecting = @subset df_ACCESS :future == 1

# ╔═╡ 77b9a47d-6e6e-4d11-8188-c76bbb6dd772
md"""
## 🖌️ Plot

With all of the data now loaded, we create our plot:
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
	m_ACCESS = mapping(color = :status => sorter(cats...) => "Status")
	marker_ACCESS = visual(markersize=25)
	
	plt = m * (data(df)*marker + data(df_ACCESS)*m_ACCESS*marker_ACCESS)
	pal = [COLORS[3], COLORS[1], COLORS[2], :grey]
	draw(plt;
		axis = (limits=(limits = ((0.0, 3_000.0), (0.0, 2.2))),),
		palettes = (color=pal,),
		#legend = (framevisible=true, valign=:inside,),
	)
end

# ╔═╡ 22483133-b4dd-447b-a909-5c99014c17b3
let
	fig = Figure()
	ax = Axis(fig[1, 1];
		xlabel = "Equilibrium temperature (K)",
		ylabel = "Planetary Radius (Rⱼ)",
		limits = ((0.0, 3_000.0), (0.0, 2.2)),
	)
	ms = 25
	
	# All transiting exoplanets
	scatter!(ax, df.pl_eqt, df.pl_radj, color=:darkgrey, markersize=12, marker='○')
	
	# ACCESS targets
	scatter!(ax, df_ACCESS_published.pl_eqt, df_ACCESS_published.pl_radj;
		markersize = ms,
		color = COLORS[3],
		label = "Published",
	)
	scatter!(ax, df_ACCESS_in_prep.pl_eqt, df_ACCESS_in_prep.pl_radj;
		markersize = ms,
		color = COLORS[1],
		label = "In prep",
	)
	scatter!(ax, df_ACCESS_underway.pl_eqt, df_ACCESS_underway.pl_radj;
		markersize = ms,
		color = COLORS[2],
		label = "Analysis underway",
		
	)
	scatter!(ax, df_ACCESS_collecting.pl_eqt, df_ACCESS_collecting.pl_radj;
		markersize = ms,
		color = :grey,
		label = "Collecting data",
	)
	
	axislegend(framevisible=true)
	
	fig
end

# ╔═╡ 04cd90c3-a405-4d22-a6de-b73f38ed4701
md"""
!!! todo
	Switch back to released version of AoG when next one is available
"""

# ╔═╡ Cell order:
# ╟─8ec24605-3e97-43ef-9dcc-989aed13bb96
# ╟─1258eb09-0413-4e53-b1b2-4025de59c9cf
# ╠═70d30677-883c-42eb-b894-5991289039b6
# ╟─307c3e44-f66a-4134-9ac8-300edea176f4
# ╠═9a2ec7d8-b0b1-4a91-8cf9-94bf19b95406
# ╟─a88bdd58-e048-4f45-86c6-7df202e05169
# ╟─86a2aa66-442b-415e-91d5-38084850fb1d
# ╠═b8db618a-411b-4642-996e-97ac1ba5fd13
# ╟─1d4fdd0d-4bea-4909-822e-231f4afa1bcf
# ╠═936682e4-3e71-4af2-9d72-b419e629858b
# ╠═71e7dad5-2812-439d-bc14-17da539b1484
# ╠═3d7acddc-2033-4c4a-90dc-df9378403301
# ╠═b74e9dce-cdc2-42c8-bed8-d855b642d312
# ╠═efcef650-78df-40b7-97a1-93c26ac007be
# ╠═0d81d22e-cead-4a21-93f7-ba07c3ede24c
# ╠═28fb4a1e-7b6b-4bc2-b27b-f91248ad8a51
# ╠═275bb8ea-5c4f-4782-9c6e-9d253f6f87ed
# ╠═0064cd4d-dfa1-4f07-afc6-387b8d83e5bf
# ╟─77b9a47d-6e6e-4d11-8188-c76bbb6dd772
# ╠═22483133-b4dd-447b-a909-5c99014c17b3
# ╟─c88dd755-0dfa-43b0-baef-83212fd3be70
# ╠═3d210896-5787-481e-9b8c-95318225e676
# ╠═fa6c24e0-2dc8-11ec-198e-0318e4603d37
# ╟─04cd90c3-a405-4d22-a6de-b73f38ed4701
