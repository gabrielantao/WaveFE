@testset "shape functions" begin
    # use the aliases for the variables from the core
    ξ, η, ζ, A = WaveCore.ξ, WaveCore.η, WaveCore.ζ, WaveCore.A
    ∂_∂ξ, ∂_∂η, ∂_∂ζ = WaveCore.∂_∂ξ, WaveCore.∂_∂η, WaveCore.∂_∂ζ
    
    @testset "integrate triangles" begin
        # reproduce example 6.2 pag 183 Hutton
        @test isequal(WaveCore.integrate_triangle(8 * ξ * η^3 - 4 * ξ * η^2), 0)
        
        # check some examples and put expected results
        @test isequal(WaveCore.integrate_triangle(-3 * ξ), -A)
        @test isequal(WaveCore.integrate_triangle(-3 * ξ * η^2), -0.1 * A)
        @test isequal(WaveCore.integrate_triangle(-ξ * η^2), -0.03333333333333333 * A)
        @test isequal(WaveCore.integrate_triangle(-2 - ξ * η^2), -2.033333333333333 * A)
        @test isequal(WaveCore.integrate_triangle(-ξ * η^2 - 2), -2.033333333333333 * A)
        @test isequal(WaveCore.integrate_triangle(-ξ * η^2 - ζ), -0.36666666666666664 * A)
    end  

    # reproduce the example 7.4 pag 243 Hutton
    @testset "integrate quadrilaterals" begin
        N = WaveCore.get_quadrilateral_shape_functions(WaveCore.ORDER_ONE::InterpolationOrder)
        ∂N_∂r = map(N_i -> WaveCore.expand_derivatives(∂_∂ξ(N_i)), N)
        ∂N_∂s = map(N_i -> WaveCore.expand_derivatives(∂_∂η(N_i)), N)
        @test isequal((∂N_∂r' * ∂N_∂r)[1, 1], 0.0625((1.0 - η)^2))
        @test isequal((∂N_∂s' * ∂N_∂s)[1, 1], 0.0625((1.0 - ξ)^2))
        @test isequal((N' * N)[1, 1], 0.0625((1.0 - ξ)^2)*((1.0 - η)^2))
        r_params = WaveCore.get_quadrature_positions(2)
        s_params = WaveCore.get_quadrature_positions(2)
        @test WaveCore.calculate_gauss_quadrature((∂N_∂r' * ∂N_∂r)[1, 1], r_params, s_params) ≈ 1 / 3
        @test WaveCore.calculate_gauss_quadrature((∂N_∂s' * ∂N_∂s)[1, 1], r_params, s_params) ≈ 1 / 3
        @test WaveCore.calculate_gauss_quadrature((N' * N)[1, 1], r_params, s_params) ≈ 4 / 9
    end


    # reproduce the example 6.8 of Hutton
    @testset "integrate with Gauss-Legendre quadrature" begin
        # the interpolation order of this function is known as 2 (see get_interpolation_order)
        expression = (ξ^3 - 1.0) * (η - 1)^2
        r_params = WaveCore.get_quadrature_positions(2)
        s_params = WaveCore.get_quadrature_positions(2)
        @test WaveCore.calculate_gauss_quadrature(expression, r_params, s_params) ≈ -5.33333333333
        
        # test the interpolation order getter
        @test WaveCore.get_interpolation_order((1.0 + η) * (1.0 + η), η) == 2
        @test WaveCore.get_interpolation_order((1.0 + η) * (1.0 - ξ) + (2.0 - ξ)^3, ξ) == 2
    end


    # reproduce the example 9.3 pag 352 Hutton
    @testset "calculate Jacobian" begin
        N = WaveCore.get_quadrilateral_shape_functions(WaveCore.ORDER_ONE::InterpolationOrder)
        J = WaveCore.calculate_jacobian(N, [1.0, 2.0, 2.25, 1.25], [0, 0, 1.5, 1.0]) 
        @test isequal(J[1, 1], 0.25(1.0 + η) + 0.25(1.0 - η))
        @test isequal(J[1, 2], 0.125(1.0 + η))
        @test isequal(J[2, 1], 0.0625(1.0 + ξ) + 0.0625(1.0 - ξ))
        @test isequal(J[2, 2], 0.375(1.0 + ξ) + 0.25(1.0 - ξ))
    end
end