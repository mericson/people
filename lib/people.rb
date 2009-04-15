module People

  # Class to parse names into their components like first, middle, last, etc.
  class NameParser

    attr_reader :seen, :parsed

    # Creates a name parsing object
    def initialize( opts={} )

      @name_chars = "A-Za-z0-9\\-\\'"
      @nc = @name_chars

      @opts = {
        :strip_mr   => true,
        :strip_mrs  => false,
        :case_mode  => 'proper',
        :couples    => false
      }.merge! opts

      ## constants

      @titles = [ 'Mr\.? and Mrs\.? ',
                  'Mrs\.? ',
                  'M/s\.? ',
                  'Ms\.? ',
                  'Miss\.? ',
                  'Mme\.? ',
                  'Mr\.? ',
                  'Messrs ',
                  'Mister ',
                  'Mast(\.|er)? ',
                  'Ms?gr\.? ',
                  'Sir ',
                  'Lord ',
                  'Lady ',
                  'Madam(e)? ',
                  'Dame ',

                  # Medical
                  'Dr\.? ',
                  'Doctor ',
                  'Sister ',
                  'Matron ',

                  # Legal
                  'Judge ',
                  'Justice ',

                  # Police
                  'Det\.? ',
                  'Insp\.? ',

                  # Military
                  'Brig(adier)? ',
                  'Capt(\.|ain)? ',
                  'Commander ',
                  'Commodore ',
                  'Cdr\.? ',
                  'Colonel ',
                  'Gen(\.|eral)? ',
                  'Field Marshall ',
                  'Fl\.? Off\.? ',
                  'Flight Officer ',
                  'Flt Lt ',
                  'Flight Lieutenant ',
                  'Pte\. ',
                  'Private ',
                  'Sgt\.? ',
                  'Sargent ',
                  'Air Commander ',
                  'Air Commodore ',
                  'Air Marshall ',
                  'Lieutenant Colonel ',
                  'Lt\.? Col\.? ',
                  'Lt\.? Gen\.? ',
                  'Lt\.? Cdr\.? ',
                  'Lieutenant ',
                  '(Lt|Leut|Lieut)\.? ',
                  'Major General ',
                  'Maj\.? Gen\.?',
                  'Major ',
                  'Maj\.? ',

                  # Religious
                  'Rabbi ',
                  'Brother ',
                  'Father ',
                  'Chaplain ',
                  'Pastor ',
                  'Bishop ',
                  'Mother Superior ',
                  'Mother ',
                  'Most Rever[e|a]nd ',
                  'Very Rever[e|a]nd ',
                  'Mt\.? Revd\.? ',
                  'V\.? Revd?\.? ',
                  'Rever[e|a]nd ',
                  'Revd?\.? ',

                  # Other
                  'Prof(\.|essor)? ',
                  'Ald(\.|erman)? '
                ];


      @suffixes = [
                   'Jn?r\.?,? Esq\.?',
                   'Sn?r\.?,? Esq\.?',
                   'I{1,3},? Esq\.?',

                   'Jn?r\.?,? M\.?D\.?',
                   'Sn?r\.?,? M\.?D\.?',
                   'I{1,3},? M\.?D\.?',

                   'Sn?r\.?',         # Senior
                   'Jn?r\.?',         # Junior

                   'Esq(\.|uire)?',
                   'Esquire.',
                   'Attorney at Law.',
                   'Attorney-at-Law.',

                   'Ph\.?d\.?',
                   'C\.?P\.?A\.?',

                   'XI{1,3}',            # 11th, 12th, 13th
                   'X',                  # 10th
                   'IV',                 # 4th
                   'VI{1,3}',            # 6th, 7th, 8th
                   'V',                  # 5th
                   'IX',                 # 9th
                   'I{1,3}\.?',             # 1st, 2nd, 3rd
                   'M\.?D\.?',           # M.D.
                   'D.?M\.?D\.?'         # M.D.
                  ];

      @last_name_p = "((;.+)|(((Mc|Mac|Des|Dell[ae]|Del|De La|De Los|Da|Di|Du|La|Le|Lo|St\.|Den|Von|Van|Von Der|Van De[nr]) )?([#{@nc}]+)))";
      @mult_name_p = "((;.+)|(((Mc|Mac|Des|Dell[ae]|Del|De La|De Los|Da|Di|Du|La|Le|Lo|St\.|Den|Von|Van|Von Der|Van De[nr]) )?([#{@nc} ]+)))";

      @seen = 0
      @parsed = 0;

    end

    def parse( name )

      @seen += 1

      clean  = ''
      out = Hash.new( "" )

      out[:orig]  = name.dup

      name = name.dup

      name = clean( name )

      # strip trailing suffices
      @suffixes.each do |sfx|
        sfx_p = Regexp.new( "(.+), (#{sfx})$", true )
        ##puts sfx_p
        name.gsub!( sfx_p, "\\1 \\2" )
      end

      name.gsub!( /Mr\.? \& Mrs\.?/i, "Mr. and Mrs." )

      # Flip last and first if contain comma
      name.gsub!( /;/, "" )
      name.gsub!( /(.+),(.+)/, "\\2 ;\\1" )


      name.gsub!( /,/, "" )
      name.strip!

      if @opts[:couples]
        name.gsub!( / +and +/i, " \& " )
      end



      if @opts[:couples] && name.match( /\&/ )

        names = name.split( / *& */ )
        a = names[0]
        b = names[1]

        out[:title2] = get_title( b );
        out[:suffix2] = get_suffix( b );

        b.strip!

        parts = get_name_parts( b )

        out[:parsed2] = parts[0]
        out[:parse_type2] = parts[1]
        out[:first2] = parts[2]
        out[:middle2] = parts[3]
        out[:last] = parts[4]

        out[:title] = get_title( a );
        out[:suffix] = get_suffix( a );

        a.strip!
        a += " "

        parts = get_name_parts( a, true )

        out[:parsed] = parts[0]
        out[:parse_type] = parts[1]
        out[:first] = parts[2]
        out[:middle] = parts[3]

        if out[:parsed] && out[:parsed2]
          out[:multiple] = true
        else
          out = Hash.new( "" )
        end


      else

        out[:title] = get_title( name );
        out[:suffix] = get_suffix( name );

        parts = get_name_parts( name )

        out[:parsed] = parts[0]
        out[:parse_type] = parts[1]
        out[:first] = parts[2]
        out[:middle] = parts[3]
        out[:last] = parts[4]

      end


      if @opts[:case_mode] == 'proper'
        [ :title, :first, :middle, :last, :suffix, :clean, :first2, :middle2, :title2, :suffix2 ].each do |part|
          out[part] = proper( out[part] )
        end

      elsif @opts[:case_mode] == 'upper'
        [ :title, :first, :middle, :last, :suffix, :clean, :first2, :middle2, :title2, :suffix2 ].each do |part|
          out[part].upcase!
        end

      else

      end

      if out[:parsed]
        @parsed += 1
      end

      out[:clean] = name





      return {
        :title       => "",
        :first       => "",
        :middle      => "",
        :last        => "",
        :suffix      => "",

        :title2      => "",
        :first2      => "",
        :middle2     => "",
        :suffix2     => "",

        :clean       => "",

        :parsed      => false,
        :parse_type  => "",

        :parsed      => false,
        :parse_type  => "",

        :parsed2     => false,
        :parse_type2 => "",

        :multiple    => false
      }.merge( out )

    end


    def clean( s )

      # remove illegal characters
      s.gsub!( /[^A-Za-z0-9\-\'\.&\/ \,]/, "" )
      # remove repeating spaces
      s.gsub!( /  +/, " " )
      s.gsub!( /\s+/, " " )
      s.strip!
      s

    end

    def get_title( name )

      @titles.each do |title|
        title_p = Regexp.new( "^(#{title})(.+)", true )
        if m = name.match( title_p )

          title = m[1]
          name.replace( m[-1].strip )
          return title
        end

      end

      return ""
    end

    def get_suffix( name )

      @suffixes.each do |sfx|
        sfx_p = Regexp.new( "(.+) (#{sfx})$", true )
        if name.match( sfx_p )
          name.replace $1.strip
          suffix = $2
          return $2
        end

      end

      return ""
    end

    def get_name_parts( name, no_last_name = false )

      first  = ""
      middle = ""
      last   = ""

      if no_last_name
        last_name_p = ''
        mult_name_p = ''
      else
        last_name_p = @last_name_p
        mult_name_p = @mult_name_p
      end

      parsed = false

      # M ERICSON
      if name.match( /^([A-Za-z])\.? (#{last_name_p})$/i )
        first  = $1;
        middle = '';
        last   = $2;
        parsed = true
        parse_type = 1;

        # M E ERICSON
      elsif name.match( /^([A-Za-z])\.? ([A-Za-z])\.? (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 2;

        # M.E. ERICSON
      elsif name.match( /^([A-Za-z])\.([A-Za-z])\. (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 3;

        # M E E ERICSON
      elsif name.match( /^([A-Za-z])\.? ([A-Za-z])\.? ([A-Za-z])\.? (#{last_name_p})$/i )
        first  = $1;
        middle = $2 + ' ' + $3;
        last   = $4;
        parsed = true
        parse_type = 4;

        # M EDWARD ERICSON
      elsif name.match( /^([A-Za-z])\.? ([#{@nc}]+) (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 5;

        # MATTHEW E ERICSON
      elsif name.match( /^([#{@nc}]+) ([A-Za-z])\.? (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 6;

        # MATTHEW E E ERICSON
      elsif name.match( /^([#{@nc}]+) ([A-Za-z])\.? ([A-Za-z])\.? (#{last_name_p})$/i )
        first  = $1;
        middle = $2 + ' ' + $3;
        last   = $4;
        parsed = true
        parse_type = 7;

        # MATTHEW E.E. ERICSON
      elsif name.match( /^([#{@nc}]+) ([A-Za-z]\.[A-Za-z]\.) (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 8;

        # MATTHEW ERICSON
      elsif name.match( /^([#{@nc}]+) (#{last_name_p})$/i )
        first  = $1;
        middle = '';
        last   = $2;
        parsed = true
        parse_type = 9;

        # MATTHEW EDWARD ERICSON
      elsif name.match( /^([#{@nc}]+) ([#{@nc}]+) (#{last_name_p})$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 10;

        # MATTHEW E. SHEIE ERICSON
      elsif name.match( /^([#{@nc}]+) ([A-Za-z])\.? ($multNamePat)$/i )
        first  = $1;
        middle = $2;
        last   = $3;
        parsed = true
        parse_type = 11;
      end

      last.gsub!( /;/, "" )

      return [ parsed, parse_type, first, middle, last ];

    end



    def proper ( name )

      fixed = name.downcase

      # Now uppercase first letter of every word. By checking on word boundaries,
      # we will account for apostrophes (D'Angelo) and hyphenated names
      fixed.gsub!( /\b(\w+)/ ) { |m| m.match( /^[ixv]$+/i ) ? m.upcase :  m.capitalize }

      # Name case Macs and Mcs
      # Exclude names with 1-2 letters after prefix like Mack, Macky, Mace
      # Exclude names ending in a,c,i,o,z or j, typically Polish or Italian

      if fixed.match( /\bMac[a-z]{2,}[^a|c|i|o|z|j]\b/i  )

        fixed.gsub!( /\b(Mac)([a-z]+)/i ) do |m|
          $1 + $2.capitalize
        end

        # Now correct for "Mac" exceptions
        fixed.gsub!( /MacHin/i,  'Machin' )
        fixed.gsub!( /MacHlin/i, 'Machlin' )
        fixed.gsub!( /MacHar/i,  'Machar' )
        fixed.gsub!( /MacKle/i,  'Mackle' )
        fixed.gsub!( /MacKlin/i, 'Macklin' )
        fixed.gsub!( /MacKie/i,  'Mackie' )

        # Portuguese
        fixed.gsub!( /MacHado/i,  'Machado' );

        # Lithuanian
        fixed.gsub!( /MacEvicius/i, 'Macevicius' )
        fixed.gsub!( /MacIulis/i,   'Maciulis' )
        fixed.gsub!( /MacIas/i,     'Macias' )

      elsif fixed.match( /\bMc/i )
        fixed.gsub!( /\b(Mc)([a-z]+)/i ) do |m|
          $1 + $2.capitalize
        end

      end

      # Exceptions (only 'Mac' name ending in 'o' ?)
      fixed.gsub!( /Macmurdo/i, 'MacMurdo' )

      return fixed

    end

  end


end

