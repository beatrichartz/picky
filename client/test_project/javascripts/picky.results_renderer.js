"use strict";

var PickyResultsRenderer = function(addination, config) {
  
  var locale = config.locale;
  
  var explanations         = config.explanations || {};
  var explanationDelimiter = config.explanationDelimiter || {
      ch: 'und',
      de: 'und',
      en: 'and',
      fr: 'et',
      it: 'e'
    };
  var explanationTokenDelimiter = config.explanationTokenDelimiter || {};
  var explanationTokenCallback  = config.explanationTokenCallback;
  
  var resultsDivider    = config['resultsDivider'];
  var allocationWrapper = config['wrapResults'];
  var nonPartial        = config['nonPartial'];
  
  // Adds asterisks to the last token.
  //
  var asteriskifyLastToken = function(combinations) {
    var last_part = combinations[combinations.length-1];
	  if (last_part === undefined) { return []; }
    var parts = combinations.slice(0, combinations.length-1);
    if (parts == []) { parts = [parts]; }
    if (!nonPartial.include(last_part[0])) {
      // Replace with * unless there is already one or a tilde.
      //
      if (last_part[1].match(/[^\*~]$/)) { last_part[1] += '*'; }
    }
    parts.push(last_part);
    return parts;
  };
  this.asteriskifyLastToken = asteriskifyLastToken; // Note: For tests.
  
  // Replaces the category with an explanation of the category.
  //
  var explainCategory = function(combination) {
    var localized_explanations = explanations[locale] || {};
    var parts = [];
    var combo;
    
    for (var i = 0, l = combination.length; i < l; i++) {
      combo = combination[i];
      var category = combo[0];
      var explanation = localized_explanations[category] || category;
      parts.push([category, explanation, combo[1]]);
    }
	
    return parts;
  };
  this.explainCategory = explainCategory; // Note: Only exposed for testing.
  
  //
  //
  var strongify = function(category, joinedTokens) {
    return ['<strong>' + category + '</strong>', joinedTokens].join(' ');
  };
  this.strongify = strongify; // Note: Only exposed for testing.
  
  var joinExplanationTokens = function(category, explainedCategory, tokens) {
    // TODO Slight speed issues here.
    //
    var explanation = explanationTokenCallback && explanationTokenCallback(category, tokens);
    if (explanation) {
      return explanation;
    } else {
      var localizedExplanationTokenDelimiter = explanationTokenDelimiter[locale] || {};
      return strongify(explainedCategory,tokens.join(localizedExplanationTokenDelimiter[category] || ' '));
    }
  };
  
  // Puts together an explanation.
  //
  // Note: Accumulates same categories using a whitespace.
  //
  var explain = function(type, combinations) {
    var localizedExplanationDelimiter = explanationDelimiter[locale] || '&';
    
    var parts = explainCategory(asteriskifyLastToken(combinations));
    var lastCategory     = '';
    var tokenAccumulator = [];
    var joinedTokens     = '';
    var replaced = []
    
    // Note: Was $.map
    parts.each(function(i, part) {
      var category          = part[0];
      var explainedCategory = part[1];
      var token             = part[2];
      
      // Remove categorization (including commas)
      // before the token.
      //
      // TODO Duplicate code.
      //
      token = token.replace(/[\w,]+:(.+)/, "$1");
      
      // Accumulate same categories.
      //
      if (lastCategory == '' || category == lastCategory) {
        tokenAccumulator.push(token);
        
        lastCategory          = category;
        lastExplainedCategory = explainedCategory;
      } else {
        var result = joinExplanationTokens(lastCategory, lastExplainedCategory, tokenAccumulator);
        
        tokenAccumulator = [];
        tokenAccumulator.push(token);
        
        lastCategory          = category;
        lastExplainedCategory = explainedCategory;
      
        replaced.push(result);
      }
    });
    
    // There might be something in the accumulator
    //
    replaced.push(joinExplanationTokens(lastCategory, lastExplainedCategory, tokenAccumulator));
    
    replaced = replaced.join(' ' + localizedExplanationDelimiter + ' ');
    replaced = '<span class="explanation">' + type + ' ' + replaced + '</span>';
	
    return replaced;
  };
  this.explain = explain; // Note: Only exposed for testing.
  
  // TODO Make customizable.
  //
  var renderHeader = function(data, allocation) {
    // TODO Make type definable. (Mapping, i18n)
    //
    var header_html = '<div class="header">';
    header_html += explain(allocation.type, allocation.combination); // TODO Rename to combinations?
    if (data.offset > 0) {
	    // TODO Add the class to the link. Remove the div.
      //
      header_html += '<div class="tothetop"><a href="#" onclick="javascript:$(\'body\').animate({scrollTop: 0}, 500);">&uarr;</a></div>';
    }
    header_html += '</div>';
    
    return header_html;
  };
  this.renderHeader = renderHeader;
  
  // Render results with the data.
  //
  this.render = function(results, data) {
    data.allocations.each(function(i, allocation) {
      // Only render if there is something to render.
      // TODO Move into methods.
      //
      if (allocation.entries.length > 0) {
        // TODO header.render(data);
        //
        results.append(renderHeader(data, allocation))
               .append(allocation.entries.join(resultsDivider));
        results.children('li').wrapAll(allocationWrapper);
      }
    });
    results.append(addination.render(data));
  };
};