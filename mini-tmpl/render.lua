
local M = {}
M._VERSION = "mini-tmpl.render 0.5.0"

local C = require "mini-tmpl.common"
local const = assert(C.const)
local validast = C.validast

local A = require "mini-tmpl.ast"
local AST = assert(A.ast)

local function internal_render(ast, parent, current)
	if type(ast)=="string" then -- use native string instead of an ast for String
		return ast
	end

	assert(parent.templates, "missing templates")
	assert(parent.rootvalues, "missing rootvalues")
	assert(parent.config, "missing config")
	assert(parent.config.dynamicfield, "missing config.dynamicfield")
	assert(parent.config.main, "missing config.main")
	assert(parent.render, "missing render")
	assert(parent.eval, "missing eval")
	assert(parent.const, "missing const")
	--assert(type(current)=="table", "current must be a table")

	if type(ast)~="table" then
		error("invalid ast type, got "..type(ast))
		return
	end

	assert(type(ast[1])=="number")
	assert(not ast[2] or ast[2]==0 or type(ast[2])=="table")
	assert(not ast[3] or ast[3]==0 or type(ast[3])=="table")

	local f = AST[ast[1]]
	if not f then
		error("no handler for ast type "..tostring(ast[1]))
	end
	local a2,a3=ast[2], ast[3]
	a2,a3 = (a2~=0 and a2 or {}), (a3~=0 and a3 or {})
	assert(type(a2)=="table" and type(a3)=="table")
	return f(ast, a2, a3, parent, current)
end

-- eval is like render but for internal use
local function eval(ast, parent, current)
--print("EVAL call:", ast[1], require"tprint"(ast))
	assert(ast[1]>=100)
	return internal_render(ast, parrent, current)
end

local function pub_render(templates, rootvalues, functions, conf) -- main, dynamicfield
	assert(type(templates)=="table")
	assert(type(rootvalues)=="table")
	functions = functions or {}
	conf = conf or {}
	assert(type(functions)=="table")
	assert(type(conf)=="table")
	local config = {
		main = conf.main or 1,
		dynamicfield = conf.dynamicfield or C.dynamicfield,
	}
	local parent = {
		templates=templates,
		rootvalues=rootvalues,
		functions=functions,
		config=config,
		render=internal_render,
		eval=eval,
		const=C.const
	}
	local ast = assert(templates[config.main])
	return internal_render(ast, parent, {})
end
M.render=pub_render

setmetatable(M, {__call=function(_, ...) return pub_render(...) end})

return M
